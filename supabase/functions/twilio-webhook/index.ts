/**
 * twilio-webhook — Edge Function de Supabase
 *
 * Recibe el POST de Twilio cuando llega un mensaje de WhatsApp al número
 * registrado (+5491125303794). Guarda la conversación y el mensaje en Supabase
 * y devuelve una respuesta TwiML vacía (acuse de recibo).
 *
 * URL a configurar en Twilio Console:
 *   Messaging → WhatsApp → Sender → "When a message comes in" (HTTP POST):
 *   https://gfvslxtqmjrelrugrcfp.supabase.co/functions/v1/twilio-webhook
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL     = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ACCOUNT_SID      = Deno.env.get("TWILIO_ACCOUNT_SID") ?? "";

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

Deno.serve(async (req) => {
  const log = (msg: string, data?: unknown) => {
    console.log(`[twilio-webhook] ${msg}`, data !== undefined ? JSON.stringify(data) : "");
  };
  const logErr = (msg: string, err?: unknown) => {
    console.error(`[twilio-webhook] ERROR: ${msg}`, err !== undefined ? err : "");
  };

  log("REQUEST RECIBIDO", { method: req.method, url: req.url });

  if (req.method !== "POST") {
    log("Rechazado: método no es POST");
    return new Response("Method Not Allowed", { status: 405 });
  }

  let rawBody: string;
  try {
    rawBody = await req.text();
    log("Body raw (primeros 500 chars)", rawBody.slice(0, 500));
  } catch (e) {
    logErr("No se pudo leer body", e);
    return twimlOk();
  }

  let params: URLSearchParams;
  try {
    params = new URLSearchParams(rawBody);
    log("Params parseados OK");
  } catch (e) {
    logErr("Error parseando body como form", e);
    return twimlOk();
  }

  const messageSid = params.get("MessageSid") ?? "";
  const from       = params.get("From") ?? "";
  const body       = params.get("Body") ?? "";
  const numMedia   = parseInt(params.get("NumMedia") ?? "0", 10);
  const accountSid = params.get("AccountSid") ?? "";

  log("Campos extraídos", {
    messageSid: messageSid.slice(0, 20),
    from,
    bodyLength: body.length,
    bodyPreview: body.slice(0, 80),
    numMedia,
    accountSid: accountSid.slice(0, 10),
    ACCOUNT_SID_env: ACCOUNT_SID ? ACCOUNT_SID.slice(0, 10) + "..." : "(vacío)",
  });

  if (ACCOUNT_SID && accountSid !== ACCOUNT_SID) {
    log("AccountSid no coincide; ignorando request. Configurá TWILIO_ACCOUNT_SID en secrets o dejalo vacío.");
    return twimlOk();
  }

  if (!from) {
    log("Campo From vacío; saliendo.");
    return twimlOk();
  }

  const mediaUrl  = numMedia > 0 ? (params.get("MediaUrl0") ?? null)  : null;
  const mediaType = numMedia > 0 ? (params.get("MediaContentType0") ?? null) : null;

  let displayName: string | null = null;
  const phoneRaw = from.replace("whatsapp:", "").replace("+", "").replace("549", "");
  log("phoneRaw para búsqueda", phoneRaw);

  try {
    const { data: empresa, error: errEmpresa } = await supabase
      .from("empresas_sin_dominio")
      .select("nombre, telefono")
      .ilike("telefono", `%${phoneRaw.slice(-8)}%`)
      .maybeSingle();
    log("Búsqueda empresas_sin_dominio", { nombre: empresa?.nombre, error: errEmpresa?.message });
    if (empresa?.nombre) displayName = empresa.nombre;

    if (!displayName) {
      const { data: lead, error: errLead } = await supabase
        .from("assistify_leads")
        .select("nombre, telefono")
        .ilike("telefono", `%${phoneRaw.slice(-8)}%`)
        .maybeSingle();
      log("Búsqueda assistify_leads", { nombre: lead?.nombre, error: errLead?.message });
      if (lead?.nombre) displayName = lead.nombre;
    }
  } catch (e) {
    logErr("Error resolviendo nombre", e);
  }

  const now = new Date().toISOString();
  log("Intentando upsert wpp_conversations", {
    phone_number: from,
    display_name: displayName,
    last_message_body: body.slice(0, 50),
  });

  const { data: conv, error: convErr } = await supabase
    .from("wpp_conversations")
    .upsert(
      {
        phone_number:      from,
        display_name:      displayName,
        last_message_at:   now,
        last_message_body: body.slice(0, 200),
      },
      { onConflict: "phone_number", ignoreDuplicates: false }
    )
    .select("id, unread_count")
    .single();

  if (convErr) {
    logErr("Upsert conversación falló", { code: convErr.code, message: convErr.message, details: convErr.details });
    return twimlOk();
  }
  if (!conv) {
    logErr("Upsert conversación: sin data en respuesta");
    return twimlOk();
  }
  log("Conversación upsert OK", { id: conv.id, unread_count: conv.unread_count });

  const newUnread = (conv.unread_count ?? 0) + 1;
  const { error: updateUnreadErr } = await supabase
    .from("wpp_conversations")
    .update({ unread_count: newUnread })
    .eq("id", conv.id);
  if (updateUnreadErr) {
    logErr("Update unread_count falló", updateUnreadErr.message);
  } else {
    log("unread_count actualizado a", newUnread);
  }

  log("Insertando mensaje en wpp_messages", {
    conversation_id: conv.id,
    twilio_sid: messageSid.slice(0, 20),
    direction: "inbound",
    bodyLength: body.length,
  });

  const { data: insertedMsg, error: msgErr } = await supabase
    .from("wpp_messages")
    .insert({
      conversation_id: conv.id,
      twilio_sid:      messageSid,
      direction:       "inbound",
      body:            body,
      media_url:       mediaUrl,
      media_type:      mediaType,
      status:          "received",
      created_at:      now,
    })
    .select("id")
    .single();

  if (msgErr) {
    logErr("Insert mensaje falló", { code: msgErr.code, message: msgErr.message, details: msgErr.details });
    return twimlOk();
  }
  log("Mensaje insertado OK", { id: insertedMsg?.id });

  log("Webhook completado OK");
  return twimlOk();
});

/** Respuesta TwiML mínima: acuse de recibo vacío. */
function twimlOk(): Response {
  return new Response(
    `<?xml version="1.0" encoding="UTF-8"?><Response></Response>`,
    {
      status: 200,
      headers: { "Content-Type": "text/xml; charset=utf-8" },
    }
  );
}
