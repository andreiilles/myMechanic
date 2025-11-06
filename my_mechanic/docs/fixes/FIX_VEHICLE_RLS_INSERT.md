# FIX: Database Error When Adding Vehicle

## Problem
When adding a new vehicle, you receive the error:
```
Database error: new row violates row-level security policy for table "vehicles"
```

## Root Cause
The Row Level Security (RLS) policies on the `vehicles` table are too restrictive and don't allow authenticated users to insert new vehicles.

## Solution

### Step 1: Run the SQL Fix in Supabase

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Create a new query and paste the following SQL:

```sql
-- =====================================================
-- FIX: Vehicle Creation RLS Policy
-- This allows authenticated users to create vehicles
-- =====================================================

-- Drop old policies that might be conflicting
DROP POLICY IF EXISTS "Users can create their own vehicles" ON vehicles;
DROP POLICY IF EXISTS "Authenticated users can create vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can insert vehicles" ON vehicles;

-- Create a simple, permissive INSERT policy
CREATE POLICY "Authenticated users can create vehicles" ON vehicles
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
  );

-- Verify the policy was created successfully
SELECT 
  schemaname,
  tablename, 
  policyname, 
  cmd as command,
  qual as using_expression,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'vehicles'
ORDER BY cmd, policyname;
```

4. Click **Run** to execute the SQL
5. Verify that you see the new policy in the output

### Step 2: Verify All Vehicle Policies

Run this query to see all current policies on the vehicles table:

```sql
SELECT 
  policyname, 
  cmd as command,
  roles,
  qual as using_expression,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'vehicles'
ORDER BY cmd, policyname;
```

You should see policies for:
- ✅ INSERT (for creating vehicles)
- ✅ SELECT (for reading vehicles)
- ✅ UPDATE (for modifying vehicles)
- ✅ DELETE (for removing vehicles)

### Step 3: Complete RLS Setup (If Needed)

If you're missing any policies, run this complete setup:

```sql
-- =====================================================
-- COMPLETE RLS SETUP FOR VEHICLES TABLE
-- =====================================================

-- Enable RLS on vehicles table
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Authenticated users can create vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can view their vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can update their vehicles" ON vehicles;
DROP POLICY IF EXISTS "Users can delete their vehicles" ON vehicles;

-- 1. INSERT Policy: Authenticated users can create vehicles
CREATE POLICY "Authenticated users can create vehicles" ON vehicles
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
  );

-- 2. SELECT Policy: Users can view vehicles they have access to
CREATE POLICY "Users can view their vehicles" ON vehicles
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT vehicle_id 
      FROM user_vehicles 
      WHERE user_id = auth.uid()
    )
  );

-- 3. UPDATE Policy: Users can update vehicles they own
CREATE POLICY "Users can update their vehicles" ON vehicles
  FOR UPDATE
  TO authenticated
  USING (
    id IN (
      SELECT vehicle_id 
      FROM user_vehicles 
      WHERE user_id = auth.uid()
      AND relationship = 'owner'
    )
  )
  WITH CHECK (
    id IN (
      SELECT vehicle_id 
      FROM user_vehicles 
      WHERE user_id = auth.uid()
      AND relationship = 'owner'
    )
  );

-- 4. DELETE Policy: Users can delete vehicles they own
CREATE POLICY "Users can delete their vehicles" ON vehicles
  FOR DELETE
  TO authenticated
  USING (
    id IN (
      SELECT vehicle_id 
      FROM user_vehicles 
      WHERE user_id = auth.uid()
      AND relationship = 'owner'
    )
  );

-- Verify all policies were created
SELECT 
  policyname, 
  cmd as command,
  roles,
  CASE 
    WHEN qual IS NOT NULL THEN 'Has USING clause'
    ELSE 'No USING clause'
  END as using_status,
  CASE 
    WHEN with_check IS NOT NULL THEN 'Has WITH CHECK clause'
    ELSE 'No WITH CHECK clause'
  END as check_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'vehicles'
ORDER BY cmd, policyname;
```

### Step 4: Test the Fix

After running the SQL:

1. Restart your Flutter app (hot restart won't work for backend changes)
2. Try adding a vehicle again
3. The vehicle should now be created successfully

## Expected Behavior After Fix

✅ Users can create new vehicles  
✅ Users can see their own vehicles  
✅ Users can update vehicles they own  
✅ Users can delete vehicles they own  
✅ Users cannot see vehicles they don't have access to

## Troubleshooting

### If it still doesn't work:

1. **Check authentication**: Make sure you're logged in
   ```dart
   final userId = SupabaseService.client.auth.currentUser?.id;
   print('Current user ID: $userId');
   ```

2. **Check the vehicle data being sent**:
   - Open the `vehicle_provider.dart` 
   - Look for debug prints in the console
   - Verify that `user_id` is being set correctly

3. **Check Supabase logs**:
   - Go to Supabase Dashboard → Logs
   - Look for any error messages
   - Check for permission denied errors

4. **Verify RLS is enabled**:
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE schemaname = 'public' 
   AND tablename = 'vehicles';
   ```
   Should return `rowsecurity = true`

### Alternative: Temporarily Disable RLS (NOT RECOMMENDED FOR PRODUCTION)

⚠️ **Only for debugging purposes:**

```sql
-- DANGER: This removes all security
ALTER TABLE vehicles DISABLE ROW LEVEL SECURITY;
```

If vehicles can be added with RLS disabled, then the issue is definitely with the policies. Re-enable RLS and fix the policies properly:

```sql
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
```

## Related Files

- SQL Fix: `/docs/database/sql/fix_vehicle_rls.sql`
- Vehicle Provider: `/lib/providers/vehicle_provider.dart`
- Add Vehicle Screen: `/lib/screens/add_vehicle_screen.dart`

## Additional Notes

### Why This Happens

Row Level Security (RLS) is a PostgreSQL feature that controls which rows users can access in a table. When enabled, you must define policies that explicitly grant access. Without proper INSERT policies, even authenticated users cannot create new records.

### Security Considerations

The fix allows any authenticated user to create vehicles. This is correct because:
1. Users should be able to add their own vehicles
2. The vehicle is automatically linked to the user through `user_vehicles` table
3. Access control is managed through the `user_vehicles` relationship table
4. Users can only see/modify vehicles they're linked to

### Related Policies to Check

Also verify these policies exist:

**user_vehicles table:**
```sql
-- Users can link themselves to vehicles
CREATE POLICY "Users can create vehicle links" ON user_vehicles
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Users can view their vehicle links
CREATE POLICY "Users can view their links" ON user_vehicles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());
```

## Prevention

To prevent this issue in the future:

1. ✅ Always test RLS policies after creation
2. ✅ Document all policy changes
3. ✅ Keep SQL migration files
4. ✅ Test all CRUD operations after enabling RLS
5. ✅ Use Supabase SQL Editor's policy helper

## Success Verification

After applying the fix, run this test:

1. Open the app
2. Log in with a test account
3. Go to "Add Vehicle" screen
4. Fill in all required fields:
   - Make: `Toyota`
   - Model: `Camry`
   - Year: `2020`
   - VIN: `TEST123456789ABCD` (17 characters)
   - Current Mileage: `50000`
5. Click "Add Vehicle"
6. ✅ Vehicle should be created successfully
7. ✅ You should see the vehicle in your list

## Contact

If the issue persists after applying these fixes:
1. Check the Supabase Dashboard → Database → Policies
2. Review the logs in Supabase Dashboard → Logs
3. Share the exact error message from the logs

---

**Status**: Ready to apply  
**Estimated time**: 5 minutes  
**Risk level**: Low (only affects development database)
