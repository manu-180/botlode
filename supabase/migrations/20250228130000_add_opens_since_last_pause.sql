-- Añade columna para pausa tanda por aperturas reales (cada 15 envíos).
ALTER TABLE public.empresas_whatsapp_limit
  ADD COLUMN IF NOT EXISTS opens_since_last_pause int NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.empresas_whatsapp_limit.opens_since_last_pause IS 'Aperturas desde la última pausa de tanda; al llegar a 15 se dispara pausa 10 min.';
