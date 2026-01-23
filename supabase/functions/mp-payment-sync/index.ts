// Archivo: supabase/functions/mp-payment-sync/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const MP_ACCESS_TOKEN = Deno.env.get('MP_ACCESS_TOKEN')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) throw new Error("Usuario no autenticado")

    const { token, brand, last_four, holder_name, expiry_date } = await req.json()
    
    // Email seguro del usuario logueado
    const safeEmail = user.email || 'guest@botslode.com';

    console.log(`[SYNC] Iniciando para: ${safeEmail}`);

    // 1. Verificar si ya tenemos el ID en nuestra Base de Datos local
    const { data: existingBilling } = await supabaseClient
      .from('user_billing')
      .select('mp_customer_id')
      .eq('user_id', user.id)
      .limit(1)
      .maybeSingle()

    let customerId = existingBilling?.mp_customer_id;

    // 2. LÓGICA DE RECUPERACIÓN INTELIGENTE (Search or Create)
    if (!customerId || customerId === 'TEMP_CUSTOMER') {
        
        // A) Primero preguntamos a Mercado Pago si este email ya existe
        console.log(`[MP] Buscando cliente por email: ${safeEmail}...`);
        const searchResponse = await fetch(`https://api.mercadopago.com/v1/customers/search?email=${safeEmail}`, {
            headers: { 'Authorization': `Bearer ${MP_ACCESS_TOKEN}` }
        });
        
        const searchData = await searchResponse.json();
        
        if (searchData.results && searchData.results.length > 0) {
            // ¡ENCONTRADO! Usamos el existente
            customerId = searchData.results[0].id;
            console.log(`[MP] Cliente existente encontrado: ${customerId}`);
        } else {
            // B) No existe, lo creamos
            console.log("[MP] No existe. Creando nuevo Customer...");
            const createResponse = await fetch('https://api.mercadopago.com/v1/customers', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${MP_ACCESS_TOKEN}`
                },
                body: JSON.stringify({ email: safeEmail })
            });
            
            const createData = await createResponse.json();
            if (!createResponse.ok) {
                 console.error("MP Create Error:", JSON.stringify(createData));
                 // Si falla, probablemente sea un error de formato de email, lanzamos error limpio
                 throw new Error(`Error MP: ${createData.message}`);
            }
            customerId = createData.id;
        }
    }

    // 3. Guardar Tarjeta en el Customer
    console.log(`[MP] Asociando tarjeta al Customer ${customerId}...`);
    const cardResponse = await fetch(`https://api.mercadopago.com/v1/customers/${customerId}/cards`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${MP_ACCESS_TOKEN}`
        },
        body: JSON.stringify({ token: token }) 
    });

    const cardData = await cardResponse.json();
    if (!cardResponse.ok) {
        console.error("MP Card Error:", JSON.stringify(cardData));
        throw new Error(`Tarjeta rechazada: ${cardData.cause?.[0]?.description || cardData.message}`);
    }

    const realCardId = cardData.id; 

    // 4. Guardar en Supabase
    // Primero borramos cualquier tarjeta "primaria" anterior para que solo haya una
    await supabaseClient.from('user_billing').update({ is_primary: false }).eq('user_id', user.id);

    const { error: dbError } = await supabaseClient.from('user_billing').insert({
        user_id: user.id,
        mp_customer_id: customerId,   
        card_token_id: realCardId,    
        card_brand: brand,
        card_last_four: last_four,
        card_holder: holder_name,
        card_expiry: expiry_date,
        is_primary: true,             
        created_at: new Date().toISOString()
    });

    if (dbError) throw new Error(`Error BD: ${dbError.message}`);

    return new Response(
      JSON.stringify({ success: true, customer_id: customerId, card_id: realCardId }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error("[ERROR SYNC]", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})