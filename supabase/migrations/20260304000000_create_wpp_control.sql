-- Tabla de auditoría para envíos de WhatsApp vía API Twilio desde botslode.
-- Registra cada intento de envío con su resultado (sent / failed / pending).
-- Si la llamada a Twilio falla, el registro queda en "pending" o "failed".

CREATE TABLE IF NOT EXISTS public.wpp_control (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  to_number     text NOT NULL,
  content_sid   text,
  parameters    text[],
  status        text DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  twilio_sid    text,
  http_status   integer,
  error_message text,
  feature       text CHECK (feature IN ('empresas', 'assistify')),
  created_at    timestamp with time zone DEFAULT now(),
  updated_at    timestamp with time zone DEFAULT now()
);

-- Índices para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_wpp_control_user_id    ON public.wpp_control (user_id);
CREATE INDEX IF NOT EXISTS idx_wpp_control_created_at ON public.wpp_control (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wpp_control_feature    ON public.wpp_control (feature);

-- RLS: cada usuario solo ve sus propios registros
ALTER TABLE public.wpp_control ENABLE ROW LEVEL SECURITY;

CREATE POLICY "wpp_control_user_policy" ON public.wpp_control
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER wpp_control_updated_at
  BEFORE UPDATE ON public.wpp_control
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
