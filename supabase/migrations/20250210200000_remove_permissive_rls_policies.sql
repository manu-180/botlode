-- Eliminar políticas RLS que permiten acceso total (qual = true).
-- Dejan de aplicarse las restrictivas por user_id = auth.uid() porque en RLS
-- PERMISSIVE varias políticas se combinan con OR.

-- ========== BOTS: quitar "acceso total" y "viewable by everyone" ==========
DROP POLICY IF EXISTS "Acceso Total Bots" ON public.bots;
DROP POLICY IF EXISTS "Public bots are viewable by everyone" ON public.bots;
DROP POLICY IF EXISTS "Users can insert their own bots" ON public.bots;

-- ========== TRANSACTIONS: quitar lectura/inserción pública ==========
DROP POLICY IF EXISTS "Permitir lectura pública de transacciones" ON public.transactions;
DROP POLICY IF EXISTS "Ver transacciones" ON public.transactions;
DROP POLICY IF EXISTS "Permitir inserción pública de transacciones" ON public.transactions;

-- Tras ejecutar esto, en bots y transactions solo quedan las políticas
-- que filtran por user_id = auth.uid(), así que cada usuario solo verá sus datos.
