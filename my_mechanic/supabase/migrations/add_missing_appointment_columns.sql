-- Add mechanic_response column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'mechanic_response'
    ) THEN
        ALTER TABLE appointments ADD COLUMN mechanic_response TEXT;
    END IF;
END $$;

-- Add proposed_by column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'appointments' 
        AND column_name = 'proposed_by'
    ) THEN
        ALTER TABLE appointments ADD COLUMN proposed_by UUID REFERENCES users(id);
    END IF;
END $$;

-- Verify columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'appointments'
ORDER BY ordinal_position;
