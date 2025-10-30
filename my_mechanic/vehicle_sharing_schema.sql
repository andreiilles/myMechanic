-- Vehicle Sharing System Database Schema
-- This allows multiple users to be linked to the same vehicle

-- Step 1: Create user_vehicles junction table
CREATE TABLE IF NOT EXISTS user_vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  relationship VARCHAR(50) DEFAULT 'owner', -- owner, family_member, shared
  added_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, vehicle_id) -- Prevent duplicate user-vehicle pairs
);

-- Step 2: Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_vehicles_user_id ON user_vehicles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_vehicles_vehicle_id ON user_vehicles(vehicle_id);

-- Step 3: Modify vehicles table - remove user_id foreign key constraint
-- The vehicle now belongs to potentially multiple users through user_vehicles table
-- We'll keep the user_id column for backward compatibility but won't use it as primary owner

-- Step 4: RLS Policies for user_vehicles table

-- Enable RLS
ALTER TABLE user_vehicles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their vehicle relationships
CREATE POLICY "Users can view their own vehicle relationships"
  ON user_vehicles FOR SELECT
  USING (auth.uid() IN (
    SELECT auth_id FROM users WHERE id = user_vehicles.user_id
  ));

-- Policy: Users can insert vehicle relationships for themselves
CREATE POLICY "Users can add vehicles to their account"
  ON user_vehicles FOR INSERT
  WITH CHECK (auth.uid() IN (
    SELECT auth_id FROM users WHERE id = user_vehicles.user_id
  ));

-- Policy: Users can delete their own vehicle relationships
CREATE POLICY "Users can remove vehicles from their account"
  ON user_vehicles FOR DELETE
  USING (auth.uid() IN (
    SELECT auth_id FROM users WHERE id = user_vehicles.user_id
  ));

-- Step 5: Update vehicles table RLS policies

-- Drop old policies
DROP POLICY IF EXISTS "Users can view their own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can insert their own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can update their own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can delete their own vehicles" ON vehicles;

-- New Policy: Users can view vehicles they have access to
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

-- New Policy: Users can insert vehicles (they will be auto-linked via trigger)
CREATE POLICY "Users can insert vehicles"
  ON vehicles FOR INSERT
  WITH CHECK (true); -- We'll handle linking in application/trigger

-- New Policy: Users can update vehicles they have access to
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

-- New Policy: Users can delete vehicles they have access to
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

-- Step 6: Create function to automatically link vehicle to creator
CREATE OR REPLACE FUNCTION link_vehicle_to_creator()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get the user_id from the auth.uid()
  SELECT id INTO v_user_id FROM users WHERE auth_id = auth.uid();
  
  -- Insert into user_vehicles
  INSERT INTO user_vehicles (user_id, vehicle_id, relationship)
  VALUES (v_user_id, NEW.id, 'owner');
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 7: Create trigger to auto-link vehicle to creator
DROP TRIGGER IF EXISTS trg_link_vehicle_to_creator ON vehicles;
CREATE TRIGGER trg_link_vehicle_to_creator
  AFTER INSERT ON vehicles
  FOR EACH ROW
  EXECUTE FUNCTION link_vehicle_to_creator();

-- Step 8: Migrate existing data (if any)
-- Link existing vehicles to their original owners via user_id
INSERT INTO user_vehicles (user_id, vehicle_id, relationship)
SELECT user_id, id, 'owner'
FROM vehicles
WHERE user_id IS NOT NULL
ON CONFLICT (user_id, vehicle_id) DO NOTHING;

-- Step 9: Update maintenance_records RLS to work with shared vehicles

-- Drop old policies
DROP POLICY IF EXISTS "Users can view maintenance for their vehicles" ON maintenance_records;
DROP POLICY IF EXISTS "Users can insert maintenance for their vehicles" ON maintenance_records;
DROP POLICY IF EXISTS "Users can update maintenance for their vehicles" ON maintenance_records;
DROP POLICY IF EXISTS "Users can delete maintenance for their vehicles" ON maintenance_records;

-- New policies for shared vehicle access
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

-- Step 10: Create function to check if VIN exists and is accessible
CREATE OR REPLACE FUNCTION check_vin_and_link(
  p_vin TEXT,
  p_user_id UUID,
  p_relationship VARCHAR(50) DEFAULT 'family_member'
)
RETURNS TABLE(
  vehicle_id UUID,
  already_linked BOOLEAN,
  vehicle_exists BOOLEAN
) AS $$
DECLARE
  v_vehicle_id UUID;
  v_already_linked BOOLEAN;
BEGIN
  -- Check if vehicle with VIN exists
  SELECT id INTO v_vehicle_id FROM vehicles WHERE vin = p_vin;
  
  IF v_vehicle_id IS NULL THEN
    -- Vehicle doesn't exist
    RETURN QUERY SELECT NULL::UUID, FALSE, FALSE;
  ELSE
    -- Check if user is already linked to this vehicle
    SELECT EXISTS(
      SELECT 1 FROM user_vehicles 
      WHERE user_id = p_user_id AND vehicle_id = v_vehicle_id
    ) INTO v_already_linked;
    
    RETURN QUERY SELECT v_vehicle_id, v_already_linked, TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 11: Create function to link existing vehicle to user
CREATE OR REPLACE FUNCTION link_user_to_vehicle(
  p_user_id UUID,
  p_vehicle_id UUID,
  p_relationship VARCHAR(50) DEFAULT 'family_member'
)
RETURNS BOOLEAN AS $$
BEGIN
  INSERT INTO user_vehicles (user_id, vehicle_id, relationship)
  VALUES (p_user_id, p_vehicle_id, p_relationship)
  ON CONFLICT (user_id, vehicle_id) DO NOTHING;
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 12: Create view to get vehicle with user count
CREATE OR REPLACE VIEW vehicles_with_users AS
SELECT 
  v.*,
  COUNT(uv.user_id) as user_count,
  ARRAY_AGG(
    json_build_object(
      'user_id', u.id,
      'first_name', u.first_name,
      'last_name', u.last_name,
      'relationship', uv.relationship
    )
  ) as shared_with
FROM vehicles v
LEFT JOIN user_vehicles uv ON v.id = uv.vehicle_id
LEFT JOIN users u ON uv.user_id = u.id
GROUP BY v.id;

-- Grant permissions
GRANT SELECT ON vehicles_with_users TO authenticated;

COMMENT ON TABLE user_vehicles IS 'Junction table linking users to vehicles for sharing access';
COMMENT ON FUNCTION check_vin_and_link IS 'Check if VIN exists and if user is already linked';
COMMENT ON FUNCTION link_user_to_vehicle IS 'Link a user to an existing vehicle';
COMMENT ON VIEW vehicles_with_users IS 'Vehicles with list of users who have access';
