// Archivo: supabase/functions/process-payment/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const MP_ACCESS_TOKEN = Deno.env.get('MP_ACCESS_TOKEN')!; 
const MP_PUBLIC_KEY = Deno.env.get('MP_PUBLIC_KEY');

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Manejo de Preflight CORS
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // 1. Verificar Usuario
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) throw new Error("Usuario no autenticado")

    const { amount_usd, card_id, token: clientToken } = await req.json()

    // --- 2. OBTENER COTIZACIÓN REAL (DOLAR BLUE) ---
    let dollarRate = 1200; // Fallback seguro por si falla la API externa
    try {
        const rateResponse = await fetch('https://dolarapi.com/v1/dolares/blue');
        if (rateResponse.ok) {
            const rateData = await rateResponse.json();
            dollarRate = rateData.venta; // Tomamos el valor de venta
            console.log(`[COTIZACION] Dolar Blue: $${dollarRate}`);
        } else {
            console.warn("[COTIZACION] API Error, usando fallback.");
        }
    } catch (e) {
        console.error("[COTIZACION] Excepción:", e);
    }

    // --- 3. CÁLCULO DE CONVERSIÓN ---
    // Convertimos los dólares de deuda a pesos argentinos para cobrar
    const amount_ars = amount_usd * dollarRate;
    
    // Mercado Pago tiene un mínimo operativo (aprox 50 pesos).
    // Aseguramos que nunca intentemos cobrar menos de 100 pesos para evitar errores 400.
    const finalAmountARS = Math.max(amount_ars, 100); 

    // --- 4. BUSCAR DATOS DE TARJETA ---
    const { data: cardDb, error: cardError } = await supabaseClient
      .from('user_billing')
      .select('mp_customer_id, card_token_id') 
      .eq('id', card_id)
      .eq('user_id', user.id)
      .single()

    if (cardError || !cardDb) throw new Error("Tarjeta no encontrada en el sistema.")

    // Validar estado de tarjeta en MP
    const cardInfoResponse = await fetch(`https://api.mercadopago.com/v1/customers/${cardDb.mp_customer_id}/cards/${cardDb.card_token_id}`, {
        headers: { 'Authorization': `Bearer ${MP_ACCESS_TOKEN}` }
    });

    if (!cardInfoResponse.ok) {
        throw new Error("La tarjeta no es válida en el procesador de pagos. Por favor elimínela y vincúlela nuevamente.");
    }
    
    const realCardData = await cardInfoResponse.json();
    const realPaymentMethodId = realCardData.payment_method.id;
    const realIssuerId = realCardData.issuer?.id; 

    // --- 5. TOKENIZACIÓN (Si es pago automático) ---
    let paymentToken = clientToken;
    if (!paymentToken) {
      if (!MP_PUBLIC_KEY) throw new Error("Configuración incompleta (Falta MP_PUBLIC_KEY).");
      
      // Regeneramos token para cobro automático server-side
      const tokenResponse = await fetch(`https://api.mercadopago.com/v1/card_tokens?public_key=${MP_PUBLIC_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ card_id: cardDb.card_token_id }) 
      });

      if (tokenResponse.ok) {
        const tokenData = await tokenResponse.json();
        paymentToken = tokenData.id;
      } else {
        throw new Error("Se requiere validación de seguridad (CVV) para esta operación.");
      }
    }

    // --- 6. EJECUTAR COBRO EN PESOS ---
    const description = `BotLode Pay - $${amount_usd.toFixed(2)} USD (T.C. $${dollarRate})`;
    
    const paymentPayload = {
      transaction_amount: Number(finalAmountARS.toFixed(2)), // MONTO EN PESOS
      token: paymentToken, 
      description: description,
      installments: 1,
      payment_method_id: realPaymentMethodId, 
      issuer_id: realIssuerId, 
      payer: {
        type: "customer",
        id: cardDb.mp_customer_id,
        email: user.email
      },
      statement_descriptor: "BOTLODE"
    };

    console.log(`[PROCESANDO] Cobrando $${finalAmountARS.toFixed(2)} ARS para cubrir $${amount_usd} USD`);

    const mpResponse = await fetch('https://api.mercadopago.com/v1/payments', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${MP_ACCESS_TOKEN}`,
        'X-Idempotency-Key': crypto.randomUUID()
      },
      body: JSON.stringify(paymentPayload)
    })

    const paymentData = await mpResponse.json()

    if (!mpResponse.ok) {
      console.error("[MP ERROR]", JSON.stringify(paymentData));
      const causes = paymentData.cause?.map((c: any) => c.description).join(' | ') || paymentData.message;
      
      // Mapeo simple de errores comunes para devolver al frontend
      if (causes.includes("funds")) throw new Error("fondos_insuficientes");
      if (causes.includes("security_code")) throw new Error("cvv_invalido");
      
      throw new Error(`Rechazo: ${causes}`);
    }

    if (paymentData.status === 'approved') {
        // --- 7. REGISTRAR TRANSACCIÓN (EN DÓLARES) ---
        // Guardamos el monto en USD para que el sistema de Billing descuente la deuda correctamente.
        await supabaseClient.from('transactions').insert({
            amount: amount_usd, // IMPORTANTE: USD
            type: 'liquidation',
            status: 'COMPLETED',
            bot_name: 'Liquidación de Saldo',
            external_payment_id: paymentData.id.toString(),
            created_at: new Date().toISOString()
        })
    } else {
        // Si está en 'in_process' o 'rejected'
        throw new Error(`El pago no fue aprobado. Estado: ${paymentData.status}`);
    }

    return new Response(
      JSON.stringify({ success: true, payment: paymentData }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})