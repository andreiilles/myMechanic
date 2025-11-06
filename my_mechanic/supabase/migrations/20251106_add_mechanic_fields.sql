-- Migration: Add missing fields to mechanics table for shop editing
-- Date: 2025-11-06
-- Description: Adds business_phone, location coordinates, accepting clients status, and fixes rating columns

-- Add business phone column
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS business_phone TEXT;

-- Add location coordinates for map display
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Add accepting clients status
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS is_accepting_clients BOOLEAN DEFAULT TRUE;

-- Rename rating to average_rating for clarity (if exists)
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'mechanics' AND column_name = 'rating'
  ) THEN
    ALTER TABLE mechanics RENAME COLUMN rating TO average_rating;
  ELSE
    ALTER TABLE mechanics ADD COLUMN IF NOT EXISTS average_rating DECIMAL(3,2) DEFAULT 0;
  END IF;
END $$;

-- Add average_rating if it doesn't exist (in case rename didn't happen)
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS average_rating DECIMAL(3,2) DEFAULT 0;

-- Ensure total_reviews exists
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;

-- Add comments for documentation
COMMENT ON COLUMN mechanics.business_phone IS 'Shop contact phone number';
COMMENT ON COLUMN mechanics.latitude IS 'Shop latitude coordinate for map display';
COMMENT ON COLUMN mechanics.longitude IS 'Shop longitude coordinate for map display';
COMMENT ON COLUMN mechanics.is_accepting_clients IS 'Whether the shop is currently accepting new clients';
COMMENT ON COLUMN mechanics.average_rating IS 'Average rating from customer reviews';
COMMENT ON COLUMN mechanics.total_reviews IS 'Total number of customer reviews';

-- Create index for efficient location queries
CREATE INDEX IF NOT EXISTS idx_mechanics_location 
ON mechanics(latitude, longitude) 
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Create index for accepting clients filter
CREATE INDEX IF NOT EXISTS idx_mechanics_accepting 
ON mechanics(is_accepting_clients) 
WHERE is_accepting_clients = TRUE;

-- Display success message
DO $$ 
BEGIN 
    RAISE NOTICE 'Successfully added missing mechanic fields!';
    RAISE NOTICE 'Added columns: business_phone, latitude, longitude, is_accepting_clients';
    RAISE NOTICE 'Fixed rating columns: average_rating, total_reviews';
END $$;
