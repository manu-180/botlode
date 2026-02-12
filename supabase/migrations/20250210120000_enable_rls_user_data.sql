-- RLS: Aislamiento de datos por usuario (auth.uid())
-- Ejecutar en Supabase SQL Editor si no usas CLI de migraciones.
-- Garantiza que cada usuario solo vea/modifique sus filas en bots, transactions y user_billing.

-- ========== BOTS ==========
ALTER TABLE IF EXISTS public.bots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bots_select_own" ON public.bots;
CREATE POLICY "bots_select_own" ON public.bots FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "bots_insert_own" ON public.bots;
CREATE POLICY "bots_insert_own" ON public.bots FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "bots_update_own" ON public.bots;
CREATE POLICY "bots_update_own" ON public.bots FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "bots_delete_own" ON public.bots;
CREATE POLICY "bots_delete_own" ON public.bots FOR DELETE USING (user_id = auth.uid());

-- ========== TRANSACTIONS ==========
ALTER TABLE IF EXISTS public.transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "transactions_select_own" ON public.transactions;
CREATE POLICY "transactions_select_own" ON public.transactions FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "transactions_insert_own" ON public.transactions;
CREATE POLICY "transactions_insert_own" ON public.transactions FOR INSERT WITH CHECK (user_id = auth.uid());

-- (UPDATE/DELETE si existen en tu esquema; ajustar según necesidad)
DROP POLICY IF EXISTS "transactions_update_own" ON public.transactions;
CREATE POLICY "transactions_update_own" ON public.transactions FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "transactions_delete_own" ON public.transactions;
CREATE POLICY "transactions_delete_own" ON public.transactions FOR DELETE USING (user_id = auth.uid());

-- ========== USER_BILLING ==========
ALTER TABLE IF EXISTS public.user_billing ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_billing_select_own" ON public.user_billing;
CREATE POLICY "user_billing_select_own" ON public.user_billing FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "user_billing_insert_own" ON public.user_billing;
CREATE POLICY "user_billing_insert_own" ON public.user_billing FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "user_billing_update_own" ON public.user_billing;
CREATE POLICY "user_billing_update_own" ON public.user_billing FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "user_billing_delete_own" ON public.user_billing;
CREATE POLICY "user_billing_delete_own" ON public.user_billing FOR DELETE USING (user_id = auth.uid());
