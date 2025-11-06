-- Migration: Add location fields to mechanics table
-- Date: 2025-11-06
-- Description: Adds latitude and longitude columns to enable map-based shop discovery

-- Add latitude and longitude columns
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Add a spatial index for efficient location queries (if PostGIS is available)
-- CREATE INDEX IF NOT EXISTS idx_mechanics_location ON mechanics USING GIST (
--   ST_MakePoint(longitude, latitude)
-- );

-- Add comment for documentation
COMMENT ON COLUMN mechanics.latitude IS 'Shop latitude coordinate for map display';
COMMENT ON COLUMN mechanics.longitude IS 'Shop longitude coordinate for map display';

-- Example update query (mechanics should set their location through the app)
-- UPDATE mechanics SET 
--   latitude = 44.4268, 
--   longitude = 26.1025 
-- WHERE id = 'your-mechanic-id';
