-- ============================================================
-- WhatsApp Inbox: conversaciones y mensajes entrantes (Twilio)
-- ============================================================

-- Una fila por número de teléfono externo que nos haya escrito o al que escribimos.
CREATE TABLE IF NOT EXISTS public.wpp_conversations (
  id               uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  phone_number     text NOT NULL UNIQUE,              -- whatsapp:+549XXXXXXXXXX
  display_name     text,                              -- nombre de empresa (si se resuelve)
  last_message_at  timestamp with time zone,
  last_message_body text,
  unread_count     integer DEFAULT 0,
  created_at       timestamp with time zone DEFAULT now(),
  updated_at       timestamp with time zone DEFAULT now()
);

-- Un mensaje por fila: inbound (nos escriben) u outbound (enviamos desde el chat).
CREATE TABLE IF NOT EXISTS public.wpp_messages (
  id              uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  conversation_id uuid REFERENCES public.wpp_conversations(id) ON DELETE CASCADE NOT NULL,
  twilio_sid      text UNIQUE,                        -- SID de Twilio (null para borradores)
  direction       text NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  body            text,
  media_url       text,                               -- URL de imagen/audio si hay adjunto
  media_type      text,                               -- MIME type del adjunto
  status          text DEFAULT 'received'
                  CHECK (status IN ('received', 'sent', 'delivered', 'read', 'failed')),
  created_at      timestamp with time zone DEFAULT now()
);

-- Índices de uso frecuente
CREATE INDEX IF NOT EXISTS idx_wpp_conv_last ON public.wpp_conversations (last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_wpp_msg_conv  ON public.wpp_messages (conversation_id, created_at);

-- Trigger para updated_at en conversaciones
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE TRIGGER wpp_conversations_updated_at
  BEFORE UPDATE ON public.wpp_conversations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS: las tablas son globales (sin user_id) porque el inbox es compartido del número Twilio.
-- Solo el service_role (Edge Functions) puede escribir; el cliente autenticado puede leer y escribir outbound.
ALTER TABLE public.wpp_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wpp_messages      ENABLE ROW LEVEL SECURITY;

-- Conversaciones: lectura libre para usuarios autenticados
CREATE POLICY "wpp_conv_select" ON public.wpp_conversations
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "wpp_conv_insert_service" ON public.wpp_conversations
  FOR INSERT WITH CHECK (true); -- inserción desde Edge Function (service_role) y cliente

CREATE POLICY "wpp_conv_update_service" ON public.wpp_conversations
  FOR UPDATE USING (true);

-- Mensajes: lectura y escritura outbound para usuarios autenticados
CREATE POLICY "wpp_msg_select" ON public.wpp_messages
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "wpp_msg_insert" ON public.wpp_messages
  FOR INSERT WITH CHECK (true);

-- Habilitar Realtime para que el cliente reciba actualizaciones en vivo
ALTER PUBLICATION supabase_realtime ADD TABLE public.wpp_conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.wpp_messages;
