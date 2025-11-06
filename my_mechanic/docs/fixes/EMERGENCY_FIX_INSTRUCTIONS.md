# 🚨 EMERGENCY FIX - App Hanging on Add Maintenance

## Problem
The app hangs when you click "Add Maintenance Record" because the `user_vehicles` table doesn't exist in your Supabase database.

## Solution (Takes 2 minutes)

### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select your project: "My Mechanic"
3. Click **"SQL Editor"** in the left sidebar

### Step 2: Run the Fix
1. Click **"New Query"** button (top right)
2. Open the file `EMERGENCY_FIX.sql` from this project folder
3. Copy **ALL** the contents
4. Paste into the SQL Editor
5. Click **"RUN"** (or press Cmd+Enter / Ctrl+Enter)
6. Wait for "Success" message

### Step 3: Restart Your App
1. Stop the Flutter app completely
2. Restart it with `flutter run`
3. Try adding a maintenance record again

## What This Fix Does

This SQL script:
- ✅ Creates the missing `user_vehicles` table
- ✅ Sets up proper security policies (RLS)
- ✅ Links existing vehicles to their owners
- ✅ Updates all database policies to work with vehicle sharing
- ✅ Enables the maintenance record feature

## Verification

After running the SQL, verify in Supabase:
1. Go to **"Table Editor"** in Supabase
2. You should see a new table: `user_vehicles`
3. It should have rows linking your user to your vehicles

## Still Having Issues?

If the app still hangs:

1. **Check Supabase Logs**:
   - Go to Supabase Dashboard → Logs
   - Look for any RLS policy errors

2. **Check Database Structure**:
   - Go to Table Editor
   - Verify `user_vehicles` table exists
   - Verify it has data (your user linked to vehicles)

3. **Clear App Data** (if needed):
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Why This Happened

The vehicle sharing feature requires the `user_vehicles` junction table to work. Without it:
- RLS policies fail (they reference this table)
- Vehicle access checks fail
- Maintenance record permissions fail
- App hangs waiting for database response

---

## Quick Command

If you're comfortable with command line and have Supabase CLI:

```bash
# From project root
cat EMERGENCY_FIX.sql | supabase db execute
```

But the dashboard method above is easier and more reliable!
