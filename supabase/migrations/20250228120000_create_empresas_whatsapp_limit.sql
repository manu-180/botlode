-- Tabla para persistir el estado del contador y límites WhatsApp (empresas sin dominio).
-- Una fila por usuario (user_id PK).

CREATE TABLE IF NOT EXISTS public.empresas_whatsapp_limit (
  user_id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  count int NOT NULL DEFAULT 0,
  window_end timestamptz,
  message_index int NOT NULL DEFAULT 0,
  last_open_at timestamptz,
  open_times jsonb NOT NULL DEFAULT '[]'::jsonb,
  daily_opens int NOT NULL DEFAULT 0,
  daily_opens_date date,
  batch_pause_until timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.empresas_whatsapp_limit IS 'Estado del contador manual y límites WhatsApp por usuario (empresas sin dominio).';

ALTER TABLE public.empresas_whatsapp_limit ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "empresas_whatsapp_limit_select_own" ON public.empresas_whatsapp_limit;
CREATE POLICY "empresas_whatsapp_limit_select_own" ON public.empresas_whatsapp_limit
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "empresas_whatsapp_limit_insert_own" ON public.empresas_whatsapp_limit;
CREATE POLICY "empresas_whatsapp_limit_insert_own" ON public.empresas_whatsapp_limit
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "empresas_whatsapp_limit_update_own" ON public.empresas_whatsapp_limit;
CREATE POLICY "empresas_whatsapp_limit_update_own" ON public.empresas_whatsapp_limit
  FOR UPDATE USING (user_id = auth.uid());

