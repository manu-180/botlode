-- ============================================================
-- DIAGNÓSTICO: Estructura de tablas y estado de RLS
-- Ejecutar en Supabase → SQL Editor y copiar/pegar el resultado
-- ============================================================

-- 1) Columnas de la tabla bots
SELECT 'TABLE: bots' AS info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'bots'
ORDER BY ordinal_position;

-- 2) Columnas de la tabla transactions (si existe)
SELECT 'TABLE: transactions' AS info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'transactions'
ORDER BY ordinal_position;

-- 3) Columnas de la tabla user_billing
SELECT 'TABLE: user_billing' AS info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'user_billing'
ORDER BY ordinal_position;

-- 4) ¿RLS está habilitado en estas tablas?
SELECT 'RLS STATUS' AS info;
SELECT relname AS table_name,
       relrowsecurity AS rls_enabled,
       relforcerowsecurity AS rls_forced
FROM pg_class
WHERE relname IN ('bots', 'transactions', 'user_billing')
  AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 5) Políticas RLS existentes en esas tablas
SELECT 'RLS POLICIES' AS info;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('bots', 'transactions', 'user_billing')
ORDER BY tablename, policyname;

-- 6) Muestra user_id de los bots (para ver a qué usuario pertenecen)
SELECT 'BOTS sample (id, name, user_id)' AS info;
SELECT id, name, user_id
FROM public.bots
ORDER BY created_at DESC
LIMIT 10;
