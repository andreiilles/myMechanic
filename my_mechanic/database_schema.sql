-- =====================================================
-- My Mechanic App Database Schema
-- =====================================================

-- 1. Users Table (Core user profiles)
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  auth_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('customer', 'mechanic')),
  phone_number TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS for users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
DROP POLICY IF EXISTS "Users can only access their own profile" ON users;
CREATE POLICY "Users can only access their own profile" ON users
  FOR SELECT USING (auth.uid() = auth_id);

DROP POLICY IF EXISTS "Authenticated users can create profile" ON users;
CREATE POLICY "Authenticated users can create profile" ON users
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL  -- Any authenticated user can insert
  );

DROP POLICY IF EXISTS "Users can update their own profile" ON users;
CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = auth_id);

DROP POLICY IF EXISTS "Users can delete their own profile" ON users;
CREATE POLICY "Users can delete their own profile" ON users
  FOR DELETE USING (auth.uid() = auth_id);

-- 2. Mechanics Table (Extended profiles for mechanics)
-- =====================================================
CREATE TABLE IF NOT EXISTS mechanics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  business_address TEXT,
  license_number TEXT,
  specializations TEXT[] DEFAULT '{}',
  rating DECIMAL(3,2) DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  is_verified BOOLEAN DEFAULT FALSE,
  description TEXT,
  hourly_rate DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS for mechanics table
ALTER TABLE mechanics ENABLE ROW LEVEL SECURITY;

-- Create policies for mechanics table
DROP POLICY IF EXISTS "Mechanics can select their own profile" ON mechanics;
CREATE POLICY "Mechanics can select their own profile" ON mechanics
  FOR SELECT USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Authenticated users can create mechanic profile" ON mechanics;
CREATE POLICY "Authenticated users can create mechanic profile" ON mechanics
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL  -- Any authenticated user can create a mechanic profile
  );

DROP POLICY IF EXISTS "Mechanics can update their own profile" ON mechanics;
CREATE POLICY "Mechanics can update their own profile" ON mechanics
  FOR UPDATE USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Mechanics can delete their own profile" ON mechanics;
CREATE POLICY "Mechanics can delete their own profile" ON mechanics
  FOR DELETE USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Anyone can view mechanic profiles" ON mechanics;
CREATE POLICY "Anyone can view mechanic profiles" ON mechanics
  FOR SELECT USING (true);

-- 3. Vehicles Table (Customer vehicles)
-- =====================================================
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER NOT NULL,
  vin TEXT UNIQUE NOT NULL,
  current_mileage INTEGER NOT NULL,
  license_plate TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS for vehicles table
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

-- Create policies for vehicles table
DROP POLICY IF EXISTS "Users can select their own vehicles" ON vehicles;
CREATE POLICY "Users can select their own vehicles" ON vehicles
  FOR SELECT USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Authenticated users can create vehicles" ON vehicles;
CREATE POLICY "Authenticated users can create vehicles" ON vehicles
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL  -- Any authenticated user can create vehicles
  );

DROP POLICY IF EXISTS "Users can update their own vehicles" ON vehicles;
CREATE POLICY "Users can update their own vehicles" ON vehicles
  FOR UPDATE USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can delete their own vehicles" ON vehicles;
CREATE POLICY "Users can delete their own vehicles" ON vehicles
  FOR DELETE USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );

-- 4. Maintenance Records Table
-- =====================================================
CREATE TABLE IF NOT EXISTS maintenance_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  description TEXT,
  cost DECIMAL(10,2) NOT NULL DEFAULT 0,
  mileage_at_service INTEGER NOT NULL,
  service_date DATE NOT NULL,
  service_provider TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS for maintenance_records table
ALTER TABLE maintenance_records ENABLE ROW LEVEL SECURITY;

-- Create policies for maintenance_records table
DROP POLICY IF EXISTS "Users can select records of their own vehicles" ON maintenance_records;
CREATE POLICY "Users can select records of their own vehicles" ON maintenance_records
  FOR SELECT USING (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      JOIN users u ON v.user_id = u.id
      WHERE u.auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can create records for their own vehicles" ON maintenance_records;
CREATE POLICY "Users can create records for their own vehicles" ON maintenance_records
  FOR INSERT WITH CHECK (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      JOIN users u ON v.user_id = u.id
      WHERE u.auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update records of their own vehicles" ON maintenance_records;
CREATE POLICY "Users can update records of their own vehicles" ON maintenance_records
  FOR UPDATE USING (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      JOIN users u ON v.user_id = u.id
      WHERE u.auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can delete records of their own vehicles" ON maintenance_records;
CREATE POLICY "Users can delete records of their own vehicles" ON maintenance_records
  FOR DELETE USING (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      JOIN users u ON v.user_id = u.id
      WHERE u.auth_id = auth.uid()
    )
  );

-- 5. Maintenance Reminders Table
-- =====================================================
CREATE TABLE IF NOT EXISTS maintenance_reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vehicle_id UUID REFERENCES vehicles(id) ON DELETE CASCADE,
  maintenance_type TEXT NOT NULL,
  reminder_type TEXT NOT NULL CHECK (reminder_type IN ('date', 'mileage', 'both')),
  reminder_date DATE,
  reminder_mileage INTEGER,
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable RLS for maintenance_reminders table
ALTER TABLE maintenance_reminders ENABLE ROW LEVEL SECURITY;

-- Create policies for maintenance_reminders table
DROP POLICY IF EXISTS "Users can select reminders of their own vehicles" ON maintenance_reminders;
CREATE POLICY "Users can select reminders of their own vehicles" ON maintenance_reminders
  FOR SELECT USING (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      JOIN users u ON v.user_id = u.id
      WHERE u.auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can create reminders for their own vehicles" ON maintenance_reminders;
CREATE POLICY "Users can create reminders for their own vehicles" ON maintenance_reminders
  FOR INSERT WITH CHECK (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      JOIN users u ON v.user_id = u.id
      WHERE u.auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update reminders of their own vehicles" ON maintenance_reminders;
CREATE POLICY "Users can update reminders of their own vehicles" ON maintenance_reminders
  FOR UPDATE USING (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      JOIN users u ON v.user_id = u.id
      WHERE u.auth_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can delete reminders of their own vehicles" ON maintenance_reminders;
CREATE POLICY "Users can delete reminders of their own vehicles" ON maintenance_reminders
  FOR DELETE USING (
    vehicle_id IN (
      SELECT v.id FROM vehicles v
      JOIN users u ON v.user_id = u.id
      WHERE u.auth_id = auth.uid()
    )
  );

-- =====================================================
-- Indexes for better performance
-- =====================================================

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_type ON users(user_type);

-- Mechanics table indexes
CREATE INDEX IF NOT EXISTS idx_mechanics_user_id ON mechanics(user_id);
CREATE INDEX IF NOT EXISTS idx_mechanics_rating ON mechanics(rating);
CREATE INDEX IF NOT EXISTS idx_mechanics_verified ON mechanics(is_verified);

-- Vehicles table indexes
CREATE INDEX IF NOT EXISTS idx_vehicles_user_id ON vehicles(user_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_vin ON vehicles(vin);

-- Maintenance records table indexes
CREATE INDEX IF NOT EXISTS idx_maintenance_records_vehicle_id ON maintenance_records(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_records_date ON maintenance_records(service_date);
CREATE INDEX IF NOT EXISTS idx_maintenance_records_type ON maintenance_records(type);

-- Maintenance reminders table indexes
CREATE INDEX IF NOT EXISTS idx_maintenance_reminders_vehicle_id ON maintenance_reminders(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_reminders_active ON maintenance_reminders(is_active);
CREATE INDEX IF NOT EXISTS idx_maintenance_reminders_date ON maintenance_reminders(reminder_date);

-- =====================================================
-- Success message
-- =====================================================
DO $$ 
BEGIN 
    RAISE NOTICE 'My Mechanic database schema created successfully!';
END $$;
