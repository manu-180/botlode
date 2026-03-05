// Envía email de recordatorio de mantenimiento (Metal Wailers) desde getbotlode.com
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MAINTENANCE_HTML = (name: string, amount: string) => `<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><style>
  body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;line-height:1.6;color:#1a1a1a;max-width:560px;margin:0 auto;background:#050505;padding:0;}
  .wrapper{background:#050505;padding:24px 16px;}
  .container{background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 4px 24px rgba(255,192,0,0.12);}
  .header{background:linear-gradient(145deg,#9A7B0A 0%,#D4AF37 50%,#E8C547 100%);padding:32px 24px;text-align:center;}
  .brand{font-size:24px;font-weight:800;color:#fff;margin:0;}
  .sub{font-size:10px;letter-spacing:2px;text-transform:uppercase;color:rgba(255,255,255,0.9);margin:4px 0 0 0;}
  .content{padding:28px 24px;}
  .title{font-size:18px;font-weight:700;color:#1a1a1a;margin:0 0 16px 0;}
  .text{font-size:15px;color:#444;margin:0 0 12px 0;}
  .amount{font-size:28px;font-weight:800;color:#9A7B0A;margin:16px 0;}
  .footer{background:#111;color:#888;font-size:11px;padding:16px 24px;text-align:center;}
</style></head>
<body>
<div class="wrapper"><div class="container">
  <div class="header"><p class="brand">BotLode</p><p class="sub">Recordatorio de mantenimiento</p></div>
  <div class="content">
    <p class="title">Hola ${name},</p>
    <p class="text">Se completó un ciclo de 30 días del <strong>Hunter Bot</strong> de Metal Wailers. El mantenimiento mensual corresponde por el período operativo.</p>
    <p class="amount">Monto: ${amount}</p>
    <p class="text">Podés abonar desde el panel de Metal Wailers con Mercado Pago (en pesos al tipo de cambio del día).</p>
    <p class="text">Cualquier duda, respondé este correo.</p>
    <p class="text" style="margin-top:20px;">Saludos,<br><strong>BotLode</strong></p>
  </div>
  <div class="footer">Email enviado desde getbotlode.com · Recordatorio automático de mantenimiento</div>
</div></div>
</body>
</html>`;

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { to_email, recipient_name, amount_usd } = await req.json();
    if (!to_email) throw new Error("Falta to_email");

    const resendKey = Deno.env.get("RESEND_API_KEY");
    if (!resendKey) throw new Error("RESEND_API_KEY no configurado");

    const from = "BotLode <manuel@getbotlode.com>";
    const subject = "Recordatorio: Mantenimiento Hunter Bot - Metal Wailers";
    const html = MAINTENANCE_HTML(recipient_name || "Santi", amount_usd ? `USD ${amount_usd}` : "USD 60");

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${resendKey}`,
      },
      body: JSON.stringify({
        from,
        to: [to_email],
        subject,
        html,
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Resend error: ${res.status} ${err}`);
    }

    const data = await res.json();
    return new Response(JSON.stringify({ ok: true, id: data.id }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error: unknown) {
    console.error("send-maintenance-reminder error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
    );
  }
});
