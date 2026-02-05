-- Ejecutar en Supabase SQL Editor (proyecto de Botslode)
-- Añade la columna initial_message a la tabla bots para el primer mensaje del bot.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'bots' AND column_name = 'initial_message'
  ) THEN
    ALTER TABLE bots ADD COLUMN initial_message TEXT;
    COMMENT ON COLUMN bots.initial_message IS 'Mensaje inicial/saludo que ve el usuario al abrir el chat con el bot.';
  END IF;
END $$;
