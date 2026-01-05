-- Disable RLS temporarily to clear everything
ALTER TABLE appointments DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view their own appointments" ON appointments;
DROP POLICY IF EXISTS "Users can create appointments" ON appointments;
DROP POLICY IF EXISTS "Customers can update their appointments" ON appointments;
DROP POLICY IF EXISTS "Mechanics can update appointments" ON appointments;

-- Re-enable RLS
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Create comprehensive RLS policies

-- 1. Allow users to view appointments where they are customer OR mechanic
CREATE POLICY "appointments_select_policy"
  ON appointments FOR SELECT
  TO authenticated
  USING (
    auth.uid() = customer_id OR 
    auth.uid() = mechanic_id
  );

-- 2. Allow authenticated users to create appointments (as customer)
CREATE POLICY "appointments_insert_policy"
  ON appointments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = customer_id);

-- 3. Allow customers to update their own appointments
CREATE POLICY "appointments_update_customer_policy"
  ON appointments FOR UPDATE
  TO authenticated
  USING (auth.uid() = customer_id)
  WITH CHECK (auth.uid() = customer_id);

-- 4. Allow mechanics to update appointments where they are the mechanic
CREATE POLICY "appointments_update_mechanic_policy"
  ON appointments FOR UPDATE
  TO authenticated
  USING (auth.uid() = mechanic_id)
  WITH CHECK (auth.uid() = mechanic_id);

-- 5. Allow users to delete their own appointments (as customer)
CREATE POLICY "appointments_delete_policy"
  ON appointments FOR DELETE
  TO authenticated
  USING (auth.uid() = customer_id);
