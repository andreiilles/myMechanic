-- Allow mechanics to view vehicle information for appointments they have
CREATE POLICY "Mechanics can view vehicles for their appointments"
ON vehicles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM appointments
    WHERE appointments.vehicle_id = vehicles.id
    AND appointments.mechanic_id = auth.uid()
  )
);
