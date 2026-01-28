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

  console.log('[INICIO] Edge Function iniciada')
  console.log('[INICIO] Método:', req.method)
  console.log('[INICIO] URL:', req.url)

  try {
    // Obtener token de autorización
    const authHeader = req.headers.get('Authorization')
    console.log('[AUTH] Authorization header:', authHeader ? 'Present' : 'Missing')
    
    if (!authHeader) {
      console.error('[AUTH] No authorization header provided')
      return new Response(
        JSON.stringify({ error: 'No authorization header' }), 
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Extraer el JWT del header (quitar "Bearer ")
    const jwt = authHeader.replace('Bearer ', '').trim()
    
    if (!jwt) {
      console.error('[AUTH] JWT is empty after extracting from header')
      return new Response(
        JSON.stringify({ error: 'Invalid authorization format' }), 
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('[AUTH] JWT extracted, length:', jwt.length)
    console.log('[AUTH] JWT first 20 chars:', jwt.substring(0, 20))
    console.log('[AUTH] JWT last 20 chars:', jwt.substring(jwt.length - 20))

    // ✅ Cliente con SERVICE_ROLE para verificar JWT
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    
    console.log('[AUTH] Service Role Key present:', serviceRoleKey ? 'YES' : 'NO')
    console.log('[AUTH] Service Role Key length:', serviceRoleKey?.length ?? 0)
    console.log('[AUTH] Supabase URL:', supabaseUrl)
    
    const supabaseAdmin = createClient(supabaseUrl ?? '', serviceRoleKey ?? '')

    // 1. Verificar Usuario con SERVICE_ROLE pasando JWT explícitamente
    console.log('[AUTH] Calling getUser with JWT...')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(jwt)
    console.log('[AUTH] getUser completed, user:', user?.id, 'error:', userError?.message)
    
    if (userError) {
      console.error('[AUTH] User verification error:', userError.message)
      return new Response(
        JSON.stringify({ 
          error: 'Authentication failed', 
          details: userError.message,
          code: 401
        }), 
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    if (!user) {
      console.error('[AUTH] No user found in JWT')
      return new Response(
        JSON.stringify({ error: 'User not authenticated', code: 401 }), 
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log('[AUTH] ✅ User authenticated:', user.id)

    const { amount_usd: raw_amount, card_id, token: clientToken } = await req.json()
    
    // 🔧 FIX: Redondear para evitar problemas de floating point
    const amount_usd = Number(raw_amount.toFixed(2))
    console.log(`[AMOUNT] Recibido: ${raw_amount}, Redondeado: ${amount_usd}`)
    
    // Crear cliente con permisos de usuario para las queries de BD
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // 🧪 MODO PRUEBAS: Sin conversión, USD se trata como ARS directo
    const dollarRate = 1; // Sin conversión para pruebas
    const amount_ars = amount_usd; // USD == ARS para pruebas
    const finalAmountARS = Math.max(Math.round(amount_ars * 100) / 100, 1); // Mínimo 1 peso, redondeado
    
    console.log(`[MODO PRUEBAS] Cobrando $${finalAmountARS} ARS (sin conversión)`);
    
    /* --- CÓDIGO ORIGINAL COMENTADO PARA PRODUCCIÓN ---
    let dollarRate = 1200; // Fallback seguro
    try {
        const rateResponse = await fetch('https://dolarapi.com/v1/dolares/blue');
        if (rateResponse.ok) {
            const rateData = await rateResponse.json();
            dollarRate = rateData.venta;
            console.log(`[COTIZACION] Dolar Blue: $${dollarRate}`);
        } else {
            console.warn("[COTIZACION] API Error, usando fallback.");
        }
    } catch (e) {
        console.error("[COTIZACION] Excepción:", e);
    }
    const amount_ars = amount_usd * dollarRate;
    const finalAmountARS = Math.max(amount_ars, 100);
    */ 

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

    // --- 6. EJECUTAR COBRO ---
    const description = `BotLode Pay - $${amount_usd.toFixed(2)} USD [MODO PRUEBAS]`;
    
    // Obtener la IP del usuario para reducir el riesgo de fraude
    const userIp = req.headers.get('x-forwarded-for') || 
                   req.headers.get('x-real-ip') || 
                   '127.0.0.1';
    
    const paymentPayload = {
      transaction_amount: Number(finalAmountARS.toFixed(2)),
      token: paymentToken, 
      description: description,
      installments: 1,
      payment_method_id: realPaymentMethodId, 
      issuer_id: realIssuerId,
      // ⚠️ NO incluir currency_id cuando se usa token - la moneda se determina por la cuenta MP
      payer: {
        type: "customer",
        id: cardDb.mp_customer_id,
        email: user.email
      },
      statement_descriptor: "BOTLODE",
      // Información adicional para reducir el score de fraude
      additional_info: {
        ip_address: userIp,
        items: [
          {
            id: "bot_service",
            title: "Servicio BotLode",
            description: "Crédito para operación de bots",
            quantity: 1,
            unit_price: Number(finalAmountARS.toFixed(2))
          }
        ]
      }
    };

    console.log(`[PROCESANDO] Cobrando $${finalAmountARS.toFixed(2)} ARS para cubrir $${amount_usd} USD`);
    console.log('[MP PAYLOAD]', JSON.stringify(paymentPayload, null, 2));

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
    console.log('[MP RESPONSE] Status:', mpResponse.status);
    console.log('[MP RESPONSE] Data:', JSON.stringify(paymentData, null, 2));

    if (!mpResponse.ok) {
      console.error("[MP ERROR] Full response:", JSON.stringify(paymentData, null, 2));
      const causes = paymentData.cause?.map((c: any) => c.description).join(' | ') || paymentData.message;
      const causesLower = causes.toLowerCase();
      
      if (causesLower.includes("funds") || causesLower.includes("insufficient")) {
        throw new Error("Tu tarjeta no tiene fondos suficientes para completar el pago.");
      }
      if (causesLower.includes("security_code") || causesLower.includes("cvv")) {
        throw new Error("El código de seguridad (CVV) es incorrecto. Verifica el dorso de tu tarjeta.");
      }
      if (causesLower.includes("expired") || causesLower.includes("expir")) {
        throw new Error("Tu tarjeta está vencida. Por favor, usa una tarjeta vigente.");
      }
      if (causesLower.includes("invalid") || causesLower.includes("transaction_amount")) {
        throw new Error("El monto de la transacción no es válido. Intenta nuevamente.");
      }
      
      throw new Error("El pago fue rechazado por tu banco. Intenta con otra tarjeta.");
    }

    console.log('[PAYMENT STATUS]', paymentData.status, '| Status Detail:', paymentData.status_detail);

    if (paymentData.status === 'approved') {
        // --- 7. REGISTRAR TRANSACCIÓN (EN DÓLARES) ---
        await supabaseClient.from('transactions').insert({
            amount: amount_usd,
            type: 'liquidation',
            status: 'COMPLETED',
            bot_name: 'Liquidación de Saldo',
            external_payment_id: paymentData.id.toString(),
            created_at: new Date().toISOString()
        })
    } else {
        // Si fue rechazado, verificar el detalle del rechazo
        if (paymentData.status === 'rejected' && paymentData.status_detail) {
          console.log(`[RECHAZO DETALLADO] Status: ${paymentData.status_detail} | live_mode: ${paymentData.live_mode} | Payer ID: ${paymentData.payer?.id}`);
          
          const detailMessages: { [key: string]: string } = {
            'cc_rejected_high_risk': '⚠️ Pago rechazado por seguridad. Si estás en producción, usa una tarjeta real o cambia a modo de pruebas con credenciales TEST.',
            'cc_rejected_insufficient_amount': 'Tu tarjeta no tiene fondos suficientes.',
            'cc_rejected_bad_filled_security_code': 'El código de seguridad (CVV) es incorrecto.',
            'cc_rejected_bad_filled_date': 'La fecha de vencimiento es incorrecta.',
            'cc_rejected_bad_filled_card_number': 'El número de tarjeta es inválido.',
            'cc_rejected_card_disabled': 'Tu tarjeta está deshabilitada. Contacta a tu banco.',
            'cc_rejected_duplicated_payment': 'Ya existe un pago similar en proceso.',
            'cc_rejected_max_attempts': 'Superaste el número máximo de intentos.'
          };
          
          const detailMessage = detailMessages[paymentData.status_detail];
          if (detailMessage) {
            console.log(`[PAYMENT STATUS] ${paymentData.status} | Status Detail: ${paymentData.status_detail}`);
            throw new Error(detailMessage);
          }
        }
        
        // Mapear estados de pago a mensajes amigables
        const statusMessages: { [key: string]: string } = {
          'rejected': 'El pago fue rechazado. Verifica tu saldo y los datos de la tarjeta.',
          'pending': 'El pago está en proceso. Te notificaremos cuando se complete.',
          'in_process': 'El pago está siendo procesado. Esto puede tomar unos minutos.',
          'cancelled': 'El pago fue cancelado.',
          'authorized': 'El pago fue autorizado pero no completado.'
        };
        
        const message = statusMessages[paymentData.status] || 'El pago no pudo ser procesado. Intenta nuevamente.';
        console.log(`[PAYMENT STATUS] ${paymentData.status}: ${message}`);
        throw new Error(message);
    }

    return new Response(
      JSON.stringify({ success: true, payment: paymentData }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})