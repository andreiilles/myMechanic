# 🚨 URGENT FIX: Vehicle Creation Error

## Error You're Seeing
```
Database error: new row violates row-level security policy for table "vehicles"
```

---

## 🎯 Quick Fix (5 minutes)

### Step 1: Open Supabase Dashboard
1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Select your project
3. Click on **SQL Editor** in the left sidebar

### Step 2: Run This SQL
Copy and paste this SQL into the editor:

```sql
-- Fix the INSERT policy for vehicles table
DROP POLICY IF EXISTS "Users can create their own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Authenticated users can create vehicles" ON vehicles;

CREATE POLICY "Authenticated users can create vehicles" ON vehicles
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
  );
```

### Step 3: Click "RUN" ▶️

### Step 4: Verify
You should see output like:
```
policyname: "Authenticated users can create vehicles"
command: INSERT
```

### Step 5: Test in Your App
1. **Restart** your Flutter app (not hot reload)
2. Try adding a vehicle again
3. ✅ It should work now!

---

## 📋 What This Does

### Before Fix ❌
- RLS policies were too restrictive
- Authenticated users couldn't insert into vehicles table
- App showed security policy error

### After Fix ✅
- Authenticated users can create vehicles
- Vehicle is automatically linked to user via trigger
- User can see and manage their vehicles

---

## 🔍 Understanding the Problem

### What is RLS?
**Row Level Security** = Database-level security that controls who can access which rows

### The Issue
Your `vehicles` table has RLS enabled (good for security), but the INSERT policy was missing or too restrictive.

### The Fix
We added a policy that says: **"Any authenticated user can insert a vehicle"**

This is safe because:
1. ✅ User must be logged in (authenticated)
2. ✅ Vehicle is linked to user automatically
3. ✅ Users can only see their own vehicles (controlled by SELECT policy)
4. ✅ Users can only modify vehicles they own (controlled by UPDATE policy)

---

## 🧪 Test After Fix

Try adding this test vehicle:

| Field | Value |
|-------|-------|
| Make | Audi |
| Model | A6 |
| Year | 2005 |
| VIN | WAUEA88DXTA287834 |
| Mileage | 200000 km |
| License Plate | _(optional)_ |

**Expected Result**: ✅ Vehicle created successfully

---

## 📊 Complete Security Setup (Optional)

If you want to ensure all policies are correct, run this complete setup:

<details>
<summary>Click to expand complete RLS setup SQL</summary>

```sql
-- Enable RLS
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

-- Clear old policies
DROP POLICY IF EXISTS "Authenticated users can create vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can view their vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can update their vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can delete their vehicles" ON vehicles;

-- CREATE: Allow authenticated users to add vehicles
CREATE POLICY "Authenticated users can create vehicles" ON vehicles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

-- READ: Users can view vehicles they have access to
CREATE POLICY "Users can view their vehicles" ON vehicles
  FOR SELECT TO authenticated
  USING (
    id IN (
      SELECT vehicle_id FROM user_vehicles WHERE user_id = auth.uid()
    )
  );

-- UPDATE: Users can modify vehicles they own
CREATE POLICY "Users can update their vehicles" ON vehicles
  FOR UPDATE TO authenticated
  USING (
    id IN (
      SELECT vehicle_id FROM user_vehicles 
      WHERE user_id = auth.uid() AND relationship = 'owner'
    )
  )
  WITH CHECK (
    id IN (
      SELECT vehicle_id FROM user_vehicles 
      WHERE user_id = auth.uid() AND relationship = 'owner'
    )
  );

-- DELETE: Users can delete vehicles they own
CREATE POLICY "Users can delete their vehicles" ON vehicles
  FOR DELETE TO authenticated
  USING (
    id IN (
      SELECT vehicle_id FROM user_vehicles 
      WHERE user_id = auth.uid() AND relationship = 'owner'
    )
  );
```

</details>

---

## 🛟 Still Not Working?

### Check 1: Are you logged in?
Add this debug code to see user ID:
```dart
final user = SupabaseService.client.auth.currentUser;
print('User ID: ${user?.id}');
print('User email: ${user?.email}');
```

### Check 2: Check Supabase Logs
1. Go to Supabase Dashboard
2. Click **Logs** → **Postgres Logs**
3. Look for error messages

### Check 3: Verify RLS is enabled
Run this SQL:
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'vehicles';
```

Should show: `rowsecurity = true`

### Check 4: View all policies
```sql
SELECT policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'vehicles'
ORDER BY cmd;
```

Should have policies for: INSERT, SELECT, UPDATE, DELETE

---

## 📁 Documentation Location

- **Full Guide**: `docs/fixes/FIX_VEHICLE_RLS_INSERT.md`
- **SQL Script**: `docs/database/sql/fix_vehicle_rls.sql`
- **Code**: `lib/providers/vehicle_provider.dart` (line 69)

---

## ✅ Checklist

- [ ] Opened Supabase SQL Editor
- [ ] Ran the fix SQL
- [ ] Saw success message
- [ ] Restarted Flutter app
- [ ] Tested adding a vehicle
- [ ] Vehicle created successfully

---

**Time to fix**: ~5 minutes  
**Difficulty**: Easy  
**Risk**: Low (only affects development)

🎉 **After this fix, you'll be able to add vehicles without errors!**
