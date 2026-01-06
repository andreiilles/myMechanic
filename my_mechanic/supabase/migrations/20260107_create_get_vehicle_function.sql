-- Create a function to get vehicle information for an appointment
-- This allows mechanics to see vehicle details for their appointments
CREATE OR REPLACE FUNCTION get_vehicle_for_appointment(
  appointment_id UUID,
  vehicle_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  vehicle_data JSON;
  is_mechanic_appointment BOOLEAN;
BEGIN
  -- Check if the current user is the mechanic for this appointment
  SELECT EXISTS (
    SELECT 1
    FROM appointments
    WHERE id = appointment_id
    AND mechanic_id = auth.uid()
  ) INTO is_mechanic_appointment;
  
  -- If not the mechanic, return null
  IF NOT is_mechanic_appointment THEN
    RETURN NULL;
  END IF;
  
  -- Get vehicle data
  SELECT row_to_json(v.*)
  INTO vehicle_data
  FROM vehicles v
  WHERE v.id = vehicle_id;
  
  RETURN vehicle_data;
END;
$$;
