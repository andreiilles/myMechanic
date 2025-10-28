-- =====================================================
-- Fix RLS Policies for Profile Creation
-- Run this in your Supabase SQL Editor
-- =====================================================

-- Fix users table policies
DROP POLICY IF EXISTS "Users can create their own profile" ON users;
DROP POLICY IF EXISTS "Authenticated users can create profile" ON users;
CREATE POLICY "Authenticated users can create profile" ON users
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL  -- Any authenticated user can insert their profile
  );

-- Fix mechanics table policies
DROP POLICY IF EXISTS "Mechanics can create their own profile" ON mechanics;
DROP POLICY IF EXISTS "Authenticated users can create mechanic profile" ON mechanics;
CREATE POLICY "Authenticated users can create mechanic profile" ON mechanics
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL  -- Any authenticated user can create a mechanic profile
  );

-- Fix vehicles table policies
DROP POLICY IF EXISTS "Users can create their own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Authenticated users can create vehicles" ON vehicles;
CREATE POLICY "Authenticated users can create vehicles" ON vehicles
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL  -- Any authenticated user can create vehicles
  );

-- Verify policies were created
SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('users', 'mechanics', 'vehicles')
ORDER BY tablename, policyname;
