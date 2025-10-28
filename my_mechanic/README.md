# My Mechanic - Car Maintenance Tracker

A Flutter app to help users manage their car maintenance, track service history, and receive reminders for important maintenance tasks.

## Features

- **User Authentication**: Secure login and registration using Supabase Auth
- **Vehicle Management**: Add, view, and manage multiple vehicles
- **Maintenance Records**: Track all maintenance activities with detailed information
- **Maintenance Reminders**: Set date or mileage-based reminders
- **Service History**: View complete maintenance history for each vehicle
- **Push Notifications**: Get notified when maintenance is due

## Use Cases Implemented

According to the use case diagram, this app implements:

1. ✅ **Register/Login**: User authentication with email/password and user role selection
2. ✅ **User Role Selection**: Choose between Customer (vehicle owner) or Mechanic
3. ✅ **Profile Creation**: Complete user profile with personal/business information
4. ✅ **Add Vehicle**: Add vehicles with VIN, make, model, year, mileage, etc. (Customers)
5. ✅ **View Vehicles**: Display list of registered vehicles (Customers)
6. 🔄 **Add Maintenance Record**: Track maintenance activities (In Progress)
7. 🔄 **View Maintenance History**: Display service history (In Progress)
8. 🔄 **Set Maintenance Reminder**: Create alerts for future maintenance (In Progress)
9. 🔄 **Receive Reminder Notification**: Push notifications (Planned)
10. 🔄 **Edit/Delete Maintenance Record**: Modify existing records (Planned)
11. ✅ **Logout**: User can sign out

## Technology Stack

- **Flutter**: Cross-platform mobile framework
- **Supabase**: Backend-as-a-Service for authentication, database, and real-time features
- **Provider**: State management
- **Google Fonts**: Typography
- **Email Validator**: Email validation

## Prerequisites

- Flutter SDK (3.9.2+)
- Dart SDK
- Supabase account
- VS Code or Android Studio

## Setup Instructions

### 1. Supabase Configuration

1. Create a new project on [Supabase](https://supabase.com)
2. Get your project URL and anon key from the project settings
3. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```
4. Update the `.env` file with your Supabase credentials:
   ```env
   SUPABASE_URL=your_supabase_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```

### 2. Database Schema

Create the following tables in your Supabase database:

#### Users Table
```sql
CREATE TABLE users (
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

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policy for users to only access their own profile
CREATE POLICY "Users can only access their own profile" ON users
  FOR ALL USING (auth.uid() = auth_id);
```

#### Mechanics Table
```sql
CREATE TABLE mechanics (
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

-- Enable RLS
ALTER TABLE mechanics ENABLE ROW LEVEL SECURITY;

-- Create policy for mechanics to access their own profile and for customers to view mechanics
CREATE POLICY "Mechanics can manage their own profile" ON mechanics
  FOR ALL USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );

CREATE POLICY "Anyone can view mechanic profiles" ON mechanics
  FOR SELECT USING (true);
```

#### Vehicles Table
```sql
CREATE TABLE vehicles (
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

-- Enable RLS (Row Level Security)
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

-- Create policy for users to only access their own vehicles
CREATE POLICY "Users can only access their own vehicles" ON vehicles
  FOR ALL USING (
    user_id IN (
      SELECT id FROM users WHERE auth_id = auth.uid()
    )
  );
```

#### Maintenance Records Table
```sql
CREATE TABLE maintenance_records (
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

-- Enable RLS
ALTER TABLE maintenance_records ENABLE ROW LEVEL SECURITY;

-- Create policy for users to access records of their own vehicles
CREATE POLICY "Users can access records of their own vehicles" ON maintenance_records
  FOR ALL USING (
    vehicle_id IN (
      SELECT id FROM vehicles WHERE user_id = auth.uid()
    )
  );
```

#### Maintenance Reminders Table
```sql
CREATE TABLE maintenance_reminders (
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

-- Enable RLS
ALTER TABLE maintenance_reminders ENABLE ROW LEVEL SECURITY;

-- Create policy for users to access reminders of their own vehicles
CREATE POLICY "Users can access reminders of their own vehicles" ON maintenance_reminders
  FOR ALL USING (
    vehicle_id IN (
      SELECT id FROM vehicles WHERE user_id = auth.uid()
    )
  );
```

### 3. Flutter Setup

1. Clone this repository
2. Set up environment variables (see step 1 above)
3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

**Note**: The `.env` file is excluded from version control for security. Make sure to create your own `.env` file based on `.env.example`.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── constants/                # App constants
│   └── app_constants.dart
├── models/                   # Data models
│   ├── app_user.dart
│   ├── mechanic.dart
│   ├── vehicle.dart
│   ├── maintenance_record.dart
│   ├── maintenance_reminder.dart
│   └── models.dart           # Export file
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   └── vehicle_provider.dart
├── screens/                  # UI screens
│   ├── auth_wrapper.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── profile_setup_screen.dart
│   ├── home_screen.dart
│   └── add_vehicle_screen.dart
├── services/                 # External services
│   └── supabase_service.dart
└── widgets/                  # Reusable UI components
    └── vehicle_card.dart
```

## MCP (Model Context Protocol) Integration

The project includes MCP configuration for Supabase integration in `.vscode/mcp.json`. This enables enhanced development experience with Supabase services through VS Code.

## Next Steps

The following features are planned for future releases:

1. **Maintenance Records Management**: Add, edit, and delete maintenance records
2. **Maintenance History**: Detailed view of all maintenance activities
3. **Reminder System**: Date and mileage-based maintenance reminders
4. **Push Notifications**: Local notifications for maintenance reminders
5. **Vehicle Details Screen**: Comprehensive vehicle information and statistics
6. **Data Export**: Export maintenance history to PDF or CSV
7. **Photo Attachments**: Add photos to maintenance records
8. **Service Provider Directory**: Manage preferred service providers

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
