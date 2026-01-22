// Archivo: supabase/functions/mp-payment-sync/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { token, email, brand, last_four, holder_name, expiry_date } = await req.json()

    // 1. Auth Check
    const authHeader = req.headers.get('Authorization')!
    const tokenStr = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(tokenStr)
    if (userError || !user) throw new Error("Usuario no autenticado")

    console.log(`💳 Agregando nueva tarjeta para ${email}...`)

    // 2. DESMARCAR CUALQUIER OTRA TARJETA COMO PRINCIPAL (La nueva será la principal)
    await supabaseAdmin
      .from('user_billing')
      .update({ is_primary: false })
      .eq('user_id', user.id)

    // 3. INSERTAR LA NUEVA TARJETA
    const { error: dbError } = await supabaseAdmin
      .from('user_billing')
      .insert({
        user_id: user.id,
        mp_customer_id: 'TEMP_CUSTOMER',
        card_token_id: token,
        card_brand: brand || 'UNKNOWN',
        card_last_four: last_four || '****',
        card_holder: holder_name,
        card_expiry: expiry_date,
        is_primary: true, // La nueva entra como principal
        updated_at: new Date().toISOString()
      })

    if (dbError) throw dbError

    return new Response(
      JSON.stringify({ message: 'Tarjeta agregada y activada' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})