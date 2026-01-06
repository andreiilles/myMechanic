-- First, check existing policies on vehicles table
SELECT tablename, policyname, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'vehicles';

-- Drop existing restrictive policy if it exists
DROP POLICY IF EXISTS "Users can only view their own vehicles" ON vehicles;

-- Create comprehensive RLS policies for vehicles table

-- Policy 1: Owners can manage their own vehicles
CREATE POLICY "Owners can manage own vehicles"
ON vehicles
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy 2: Mechanics can view vehicles for their appointments
CREATE POLICY "Mechanics can view vehicles for appointments"
ON vehicles
FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT vehicle_id
    FROM appointments
    WHERE mechanic_id = auth.uid()
  )
);
