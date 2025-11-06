-- EMERGENCY FIX: Minimal Schema to Make App Work
-- Run this in Supabase SQL Editor NOW

-- Step 1: Create user_vehicles table
CREATE TABLE IF NOT EXISTS user_vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  relationship VARCHAR(50) DEFAULT 'owner',
  added_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, vehicle_id)
);

-- Step 2: Create indexes
CREATE INDEX IF NOT EXISTS idx_user_vehicles_user_id ON user_vehicles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_vehicles_vehicle_id ON user_vehicles(vehicle_id);

-- Step 3: Enable RLS
ALTER TABLE user_vehicles ENABLE ROW LEVEL SECURITY;

-- Step 4: Policies for user_vehicles
DROP POLICY IF EXISTS "Users can view their own vehicle relationships" ON user_vehicles;
CREATE POLICY "Users can view their own vehicle relationships"
  ON user_vehicles FOR SELECT
  USING (auth.uid() IN (
    SELECT auth_id FROM users WHERE id = user_vehicles.user_id
  ));

DROP POLICY IF EXISTS "Users can add vehicles to their account" ON user_vehicles;
CREATE POLICY "Users can add vehicles to their account"
  ON user_vehicles FOR INSERT
  WITH CHECK (auth.uid() IN (
    SELECT auth_id FROM users WHERE id = user_vehicles.user_id
  ));

DROP POLICY IF EXISTS "Users can remove vehicles from their account" ON user_vehicles;
CREATE POLICY "Users can remove vehicles from their account"
  ON user_vehicles FOR DELETE
  USING (auth.uid() IN (
    SELECT auth_id FROM users WHERE id = user_vehicles.user_id
  ));

-- Step 5: Migrate existing vehicles
INSERT INTO user_vehicles (user_id, vehicle_id, relationship)
SELECT user_id, id, 'owner'
FROM vehicles
WHERE user_id IS NOT NULL
ON CONFLICT (user_id, vehicle_id) DO NOTHING;

-- Step 6: Create trigger to auto-link new vehicles
CREATE OR REPLACE FUNCTION link_vehicle_to_creator()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
  
  IF v_user_id IS NOT NULL THEN
    INSERT INTO user_vehicles (user_id, vehicle_id, relationship)
    VALUES (v_user_id, NEW.id, 'owner')
    ON CONFLICT (user_id, vehicle_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_link_vehicle_to_creator ON vehicles;
CREATE TRIGGER trg_link_vehicle_to_creator
  AFTER INSERT ON vehicles
  FOR EACH ROW
  EXECUTE FUNCTION link_vehicle_to_creator();

-- Step 7: Update vehicles RLS policies
DROP POLICY IF EXISTS "Users can select their own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Authenticated users can create vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can update their own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can delete their own vehicles" ON vehicles;

CREATE POLICY "Users can view vehicles they have access to"
  ON vehicles FOR SELECT
  USING (
    id IN (
      SELECT vehicle_id FROM user_vehicles
      WHERE user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can insert vehicles"
  ON vehicles FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update vehicles they have access to"
  ON vehicles FOR UPDATE
  USING (
    id IN (
      SELECT vehicle_id FROM user_vehicles
      WHERE user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can delete vehicles they have access to"
  ON vehicles FOR DELETE
  USING (
    id IN (
      SELECT vehicle_id FROM user_vehicles
      WHERE user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
      )
    )
  );

-- Step 8: Update maintenance_records RLS policies
DROP POLICY IF EXISTS "Users can select records of their own vehicles" ON maintenance_records;
DROP POLICY IF EXISTS "Users can create records for their own vehicles" ON maintenance_records;
DROP POLICY IF EXISTS "Users can update records of their own vehicles" ON maintenance_records;
DROP POLICY IF EXISTS "Users can delete records of their own vehicles" ON maintenance_records;

CREATE POLICY "Users can view maintenance for accessible vehicles"
  ON maintenance_records FOR SELECT
  USING (
    vehicle_id IN (
      SELECT vehicle_id FROM user_vehicles
      WHERE user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can insert maintenance for accessible vehicles"
  ON maintenance_records FOR INSERT
  WITH CHECK (
    vehicle_id IN (
      SELECT vehicle_id FROM user_vehicles
      WHERE user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can update maintenance for accessible vehicles"
  ON maintenance_records FOR UPDATE
  USING (
    vehicle_id IN (
      SELECT vehicle_id FROM user_vehicles
      WHERE user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
      )
    )
  );

CREATE POLICY "Users can delete maintenance for accessible vehicles"
  ON maintenance_records FOR DELETE
  USING (
    vehicle_id IN (
      SELECT vehicle_id FROM user_vehicles
      WHERE user_id IN (
        SELECT id FROM users WHERE auth_id = auth.uid()
      )
    )
  );

-- DONE! Your app should work now.
