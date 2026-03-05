-- Totales por feature para las cards PEND/HOY/FAIL/ENVIADOS (empresas y assistify).
ALTER TABLE public.empresas_whatsapp_limit
  ADD COLUMN IF NOT EXISTS empresas_total_sent int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS empresas_total_failed int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS assistify_total_sent int NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS assistify_total_failed int NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.empresas_whatsapp_limit.empresas_total_sent IS 'Total enviados (API o fallback) desde Empresas sin dominio.';
COMMENT ON COLUMN public.empresas_whatsapp_limit.empresas_total_failed IS 'Total fallidos en cola Empresas.';
COMMENT ON COLUMN public.empresas_whatsapp_limit.assistify_total_sent IS 'Total enviados desde Assistify.';
COMMENT ON COLUMN public.empresas_whatsapp_limit.assistify_total_failed IS 'Total fallidos en cola Assistify.';
