-- Check current status constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'appointments'::regclass 
AND conname LIKE '%status%';

-- Drop old constraint if exists
ALTER TABLE appointments DROP CONSTRAINT IF EXISTS appointments_status_check;

-- Add new constraint with all statuses
ALTER TABLE appointments ADD CONSTRAINT appointments_status_check 
CHECK (status IN ('pending', 'accepted', 'declined', 'proposed', 'confirmed', 'inProgress', 'completed', 'cancelled'));
