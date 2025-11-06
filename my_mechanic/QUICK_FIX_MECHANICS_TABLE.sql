-- =====================================================
-- QUICK FIX: Add Missing Mechanic Fields
-- =====================================================
-- Run this in your Supabase SQL Editor to fix the shop editing issue
-- This adds all the missing columns that the app expects

-- 1. Add business phone
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS business_phone TEXT;

-- 2. Add location coordinates
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;

ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- 3. Add accepting clients status
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS is_accepting_clients BOOLEAN DEFAULT TRUE;

-- 4. Fix rating column (rename if exists, or add if missing)
DO $$ 
BEGIN
  -- Try to rename 'rating' to 'average_rating'
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'mechanics' AND column_name = 'rating'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'mechanics' AND column_name = 'average_rating'
  ) THEN
    ALTER TABLE mechanics RENAME COLUMN rating TO average_rating;
  END IF;
END $$;

-- 5. Ensure average_rating exists
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS average_rating DECIMAL(3,2) DEFAULT 0;

-- 6. Ensure total_reviews exists
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;

-- 7. Update existing records to have default values
UPDATE mechanics 
SET is_accepting_clients = TRUE 
WHERE is_accepting_clients IS NULL;

UPDATE mechanics 
SET average_rating = 0 
WHERE average_rating IS NULL;

UPDATE mechanics 
SET total_reviews = 0 
WHERE total_reviews IS NULL;

-- 8. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_mechanics_location 
ON mechanics(latitude, longitude) 
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_mechanics_accepting 
ON mechanics(is_accepting_clients) 
WHERE is_accepting_clients = TRUE;

-- =====================================================
-- Verification Query
-- =====================================================
-- Run this to verify all columns exist:

SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'mechanics'
ORDER BY ordinal_position;

-- =====================================================
-- Success!
-- =====================================================
-- Your mechanics table now has all required fields.
-- You can now edit shop details in the app!
