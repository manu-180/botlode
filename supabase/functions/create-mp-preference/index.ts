// Archivo: supabase/functions/create-mp-preference/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { MercadoPagoConfig, Preference } from 'npm:mercadopago';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    // 1. LEER DATOS DEL CUERPO (Ya no del token)
    // Ahora confiamos en que la App nos manda quién es el usuario
    const { amount, email, userId } = await req.json()

    // Validación básica
    if (!amount) throw new Error("Falta el monto (amount)")
    
    // Configuración MP
    const mpAccessToken = Deno.env.get('MP_ACCESS_TOKEN')
    if (!mpAccessToken) throw new Error("Server Error: MP Token no configurado")

    const client = new MercadoPagoConfig({ accessToken: mpAccessToken });
    const preference = new Preference(client);

    // 2. CREAR PREFERENCIA PÚBLICA
    const result = await preference.create({
      body: {
        items: [
          {
            id: 'bot-cycle-charge',
            title: 'Suscripción Operativa - Ciclo Bot',
            quantity: 1,
            currency_id: 'ARS', 
            unit_price: Number(amount)
          }
        ],
        payer: {
          email: email || 'guest@botslode.com' // Fallback si no hay email
        },
        back_urls: {
          success: "botslode://payment-result?status=approved",
          failure: "botslode://payment-result?status=rejected",
          pending: "botslode://payment-result?status=pending"
        },
        auto_return: "approved",
        // Usamos el ID que nos mandó la app explícitamente
        external_reference: userId || 'GUEST_USER', 
        metadata: {
          user_id: userId,
          source: 'botslode_terminal_public'
        }
      }
    });

    console.log("✅ Preferencia Pública Creada:", result.id);

    return new Response(
      JSON.stringify({ 
        init_point: result.init_point, 
        sandbox_init_point: result.sandbox_init_point 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    console.error("🔴 Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})