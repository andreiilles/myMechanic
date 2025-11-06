# Fix: user_vehicles Table Missing

## Problem
The app is showing this error:
```
Could not find the table 'public.user_vehicles' in the schema cache
```

This means the `user_vehicles` table hasn't been created in your Supabase database yet.

## Solution

You need to run the SQL schema to create the required tables and policies.

### Step 1: Open Supabase Dashboard

1. Go to https://supabase.com/dashboard
2. Select your project
3. Click on **SQL Editor** in the left sidebar

### Step 2: Run the Schema

1. Click **New Query** button
2. Open the file `vehicle_sharing_schema.sql` from this project
3. Copy ALL the contents (all 259 lines)
4. Paste into the Supabase SQL Editor
5. Click **RUN** button (or press Cmd/Ctrl + Enter)

### Step 3: Verify Creation

After running the SQL, verify the table was created:

1. In Supabase dashboard, go to **Table Editor**
2. You should see a new table called `user_vehicles`
3. It should have these columns:
   - id (UUID)
   - user_id (UUID)
   - vehicle_id (UUID)
   - relationship (VARCHAR)
   - added_at (TIMESTAMP)

### Step 4: Restart Your App

1. Stop the Flutter app
2. Run `flutter clean`
3. Run `flutter pub get`
4. Restart the app

The error should now be resolved!

---

## What This Schema Does

The `vehicle_sharing_schema.sql` file creates:

1. **user_vehicles table** - Junction table linking users to vehicles
2. **Indexes** - For faster database queries
3. **RLS Policies** - Security rules for the table
4. **Triggers** - Automatically link vehicle creators as owners
5. **Updated policies** - For vehicles and maintenance_records tables

This enables the vehicle sharing feature where multiple users can access the same vehicle.

---

## Alternative: Command Line (Advanced)

If you have Supabase CLI installed:

```bash
# Make sure you're logged in
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Run the migration
supabase db push
```

But the dashboard method above is easier and more reliable!
