-- Add foreign key constraint for appointments.vehicle_id if it doesn't exist
DO $$ 
BEGIN
    -- Check if the foreign key constraint already exists
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'appointments_vehicle_id_fkey' 
        AND table_name = 'appointments'
    ) THEN
        -- Add the foreign key constraint
        ALTER TABLE appointments 
        ADD CONSTRAINT appointments_vehicle_id_fkey 
        FOREIGN KEY (vehicle_id) 
        REFERENCES vehicles(id) 
        ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key constraint appointments_vehicle_id_fkey added successfully';
    ELSE
        RAISE NOTICE 'Foreign key constraint appointments_vehicle_id_fkey already exists';
    END IF;
END $$;
