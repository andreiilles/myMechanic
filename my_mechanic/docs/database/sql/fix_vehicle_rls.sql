-- =====================================================
-- QUICK FIX: Vehicle Creation RLS Policy
-- Run this NOW in your Supabase SQL Editor
-- =====================================================
-- Problem: "new row violates row-level security policy"
-- Solution: Allow authenticated users to insert vehicles
-- =====================================================

-- Drop old policies that might be conflicting
DROP POLICY IF EXISTS "Users can create their own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Authenticated users can create vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can insert vehicles" ON vehicles;

-- Create a simple, permissive INSERT policy
CREATE POLICY "Authenticated users can create vehicles" ON vehicles
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
  );

-- Verify the policy was created successfully
SELECT 
  schemaname,
  tablename, 
  policyname, 
  cmd as command,
  roles,
  qual as using_expression,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'vehicles'
ORDER BY cmd, policyname;

-- =====================================================
-- OPTIONAL: Complete RLS Setup for Vehicles
-- Run this if you want to ensure all policies are correct
-- =====================================================

/*
-- Enable RLS on vehicles table (if not already enabled)
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Authenticated users can create vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can view their vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can update their vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can delete their vehicles" ON vehicles;

-- 1. INSERT Policy: Authenticated users can create vehicles
CREATE POLICY "Authenticated users can create vehicles" ON vehicles
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
  );

-- 2. SELECT Policy: Users can view vehicles they have access to
CREATE POLICY "Users can view their vehicles" ON vehicles
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT vehicle_id 
      FROM user_vehicles 
      WHERE user_id = auth.uid()
    )
  );

-- 3. UPDATE Policy: Users can update vehicles they own
CREATE POLICY "Users can update their vehicles" ON vehicles
  FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT vehicle_id 
      FROM user_vehicles 
      WHERE user_id = auth.uid()
      AND relationship = 'owner'
    )
  )
  WITH CHECK (
    id IN (
      SELECT vehicle_id 
      FROM user_vehicles 
      WHERE user_id = auth.uid()
      AND relationship = 'owner'
    )
  );

-- 4. DELETE Policy: Users can delete vehicles they own
CREATE POLICY "Users can delete their vehicles" ON vehicles
  FOR DELETE
  TO authenticated
  USING (
    id IN (
      SELECT vehicle_id 
      FROM user_vehicles 
      WHERE user_id = auth.uid()
      AND relationship = 'owner'
    )
  );

-- Final verification
SELECT 
  policyname, 
  cmd as command,
  roles,
  CASE 
    WHEN qual IS NOT NULL THEN 'Has USING clause'
    ELSE 'No USING clause'
  END as using_status,
  CASE 
    WHEN with_check IS NOT NULL THEN 'Has WITH CHECK clause'
    ELSE 'No WITH CHECK clause'
  END as check_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'vehicles'
ORDER BY cmd, policyname;
*/
