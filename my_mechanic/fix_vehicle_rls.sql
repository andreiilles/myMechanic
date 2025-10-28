-- =====================================================
-- QUICK FIX: Vehicle Creation RLS Policy
-- Run this NOW in your Supabase SQL Editor
-- =====================================================

-- Fix the vehicles table INSERT policy
DROP POLICY IF EXISTS "Users can create their own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Authenticated users can create vehicles" ON vehicles;

CREATE POLICY "Authenticated users can create vehicles" ON vehicles
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
  );

-- Verify the policy was created
SELECT 
  schemaname,
  tablename, 
  policyname, 
  cmd as command,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'vehicles'
  AND cmd = 'INSERT';
