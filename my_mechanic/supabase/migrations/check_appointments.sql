-- Check all appointments in the database
SELECT 
  id,
  customer_id,
  mechanic_id,
  service_type,
  status,
  appointment_date,
  created_at
FROM appointments
ORDER BY created_at DESC;
