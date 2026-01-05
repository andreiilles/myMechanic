-- Disable RLS temporarily
ALTER TABLE appointments DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'appointments') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON appointments';
    END LOOP;
END $$;

-- Re-enable RLS
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Simple policies - allow authenticated users to do everything for now
CREATE POLICY "Allow authenticated users to view appointments"
  ON appointments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to create appointments"
  ON appointments FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update appointments"
  ON appointments FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to delete appointments"
  ON appointments FOR DELETE
  TO authenticated
  USING (true);
