# VIN "Already Exists" Error - Troubleshooting Guide

## Problem
Getting "VIN already exists" or "duplicate key" errors when trying to add new vehicles with unique VINs.

## Root Cause
The error `user_vehicles_user_id_vehicle_id_key` indicates that:
1. You're trying to create a link between a user and vehicle that already exists
2. This could be due to:
   - Duplicate entries in user_vehicles table
   - The trigger firing when it shouldn't
   - Local vehicle list being out of sync with database

## Diagnostic Steps

### Step 1: Check for Duplicate Entries in Database
Run this SQL in your Supabase SQL Editor:

```sql
-- Check for duplicate user_vehicles entries
SELECT 
    user_id,
    vehicle_id,
    COUNT(*) as count
FROM user_vehicles
GROUP BY user_id, vehicle_id
HAVING COUNT(*) > 1;
```

If you see any results, you have duplicates that need to be cleaned up.

### Step 2: Clean Up Duplicates
If duplicates exist, run this cleanup script:

```sql
-- Delete duplicates (keep the first one, delete the rest)
DELETE FROM user_vehicles
WHERE id IN (
    SELECT id
    FROM (
        SELECT 
            id,
            ROW_NUMBER() OVER (PARTITION BY user_id, vehicle_id ORDER BY created_at ASC) as row_num
        FROM user_vehicles
    ) t
    WHERE row_num > 1
);
```

### Step 3: Verify Trigger is Working
Run this SQL to check the trigger exists:

```sql
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'auto_link_vehicle_to_user';
```

Expected output:
- trigger_name: `auto_link_vehicle_to_user`
- event_manipulation: `INSERT`
- event_object_table: `vehicles`
- action_statement: Should contain INSERT INTO user_vehicles

### Step 4: Test the Flow Manually
In Supabase SQL Editor:

```sql
-- Get your user ID
SELECT id, email FROM auth.users WHERE email = 'your-email@example.com';

-- Check your current vehicles
SELECT v.*, uv.relationship 
FROM vehicles v
JOIN user_vehicles uv ON v.id = uv.vehicle_id
WHERE uv.user_id = 'YOUR-USER-ID';

-- Try to manually insert a test vehicle
INSERT INTO vehicles (user_id, make, model, year, vin, current_mileage)
VALUES ('YOUR-USER-ID', 'Test', 'Car', 2024, 'TEST-VIN-123', 50000)
RETURNING *;

-- Check if trigger created the user_vehicles link
SELECT * FROM user_vehicles 
WHERE vehicle_id = (SELECT id FROM vehicles WHERE vin = 'TEST-VIN-123');

-- Clean up test vehicle
DELETE FROM vehicles WHERE vin = 'TEST-VIN-123';
```

### Step 5: Check App Debug Logs
Run the app and try to add a vehicle. Look for these debug messages:

```
flutter: Checking for existing vehicle with VIN: <VIN>
flutter: Found existing vehicle with VIN: <VIN>, ID: <ID>  (or)
flutter: No existing vehicle found, creating new vehicle with VIN: <VIN>
flutter: Vehicle created successfully with ID: <ID>
flutter: Trigger successfully created user_vehicles link  (or)
flutter: WARNING: Trigger did not create user_vehicles link, creating manually
flutter: PostgreSQL error adding vehicle: 23505 - <error message>
```

## Quick Fixes

### Fix 1: Clear Local App State
1. Stop the app
2. Hot restart (`r` in terminal)
3. Try adding vehicle again

### Fix 2: Force Reload Vehicles
After any error, the local vehicle list might be out of sync:
1. Navigate away from the vehicles screen
2. Navigate back (this should reload the list)
3. Try adding vehicle again

### Fix 3: Clear All Data and Start Fresh
```sql
-- WARNING: This will delete ALL vehicles and links
-- Only run if you want to start completely fresh
DELETE FROM user_vehicles;
DELETE FROM vehicles;
```

## Expected Behavior After Fix

### Scenario 1: Adding New Vehicle (Unique VIN)
1. Enter VIN: `ABC123` (not in database)
2. Debug log: "No existing vehicle found, creating new vehicle with VIN: ABC123"
3. Debug log: "Vehicle created successfully with ID: xxx"
4. Debug log: "Trigger successfully created user_vehicles link"
5. Result: ✅ Green snackbar "Vehicle added successfully"

### Scenario 2: Linking to Existing Vehicle (Shared VIN)
1. User A adds vehicle with VIN: `XYZ789`
2. User B enters same VIN: `XYZ789`
3. Debug log: "Found existing vehicle with VIN: XYZ789, ID: xxx"
4. Debug log: "Linking user to existing vehicle"
5. Debug log: "Successfully linked to existing vehicle"
6. Result: ✅ Green snackbar "Vehicle linked successfully! You now have shared access to this vehicle."

### Scenario 3: Already Linked (True Duplicate)
1. User A already has vehicle with VIN: `DEF456`
2. User A tries to add vehicle with same VIN: `DEF456`
3. Debug log: "Found existing vehicle with VIN: DEF456, ID: xxx"
4. Debug log: "User already has access to this vehicle"
5. Result: ❌ Red snackbar "You already have access to this vehicle."

## Code Changes Made

1. **Added `AddVehicleResult` class** - Distinguishes between new/linked/error
2. **Improved error handling** - Separate handling for VIN conflicts vs user_vehicles conflicts
3. **Added trigger verification** - Checks if trigger created link, creates manually if not
4. **Enhanced debug logging** - Traces the entire flow for debugging
5. **Better error messages** - More specific error messages based on constraint name

## If Problem Persists

1. **Check your internet connection** - Slow connection might cause timing issues
2. **Check Supabase dashboard** - Look for rate limiting or errors
3. **Review RLS policies** - Make sure they're not blocking the trigger
4. **Share debug logs** - Run the app and share the complete debug output
