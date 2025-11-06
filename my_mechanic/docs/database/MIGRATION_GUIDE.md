# RLS Policy Cleanup and Migration Guide

## Problem
Your Supabase database has **many duplicate and conflicting RLS policies** on the `vehicles` and `user_vehicles` tables. This causes:
- All users seeing all vehicles (security issue)
- Unpredictable behavior due to policy conflicts
- Maintenance nightmare

## Solution
Apply a comprehensive cleanup migration that:
1. Drops ALL existing policies
2. Creates a clean, minimal set of 7 policies
3. Ensures proper security and access control

---

## Step-by-Step Instructions

### Step 1: Open Supabase SQL Editor
1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**

### Step 2: Apply Cleanup Migration
1. Open the file: `supabase/migrations/cleanup_all_policies.sql`
2. Copy the entire contents
3. Paste into the SQL Editor
4. Click **Run** (or press Cmd/Ctrl + Enter)
5. Wait for "Success" message

### Step 3: Verify the Cleanup
1. Click **New Query** in SQL Editor
2. Open the file: `supabase/migrations/verify_clean_policies.sql`
3. Copy the entire contents
4. Paste into the SQL Editor
5. Click **Run**
6. Review the results:

**Expected Results:**
```
1. RLS Enabled Check:
   ✅ vehicles: rowsecurity = true
   ✅ user_vehicles: rowsecurity = true

2. Vehicles Policies:
   ✅ 4 policies exactly:
      - vehicles_insert_policy
      - vehicles_select_policy
      - vehicles_update_policy
      - vehicles_delete_policy

3. User Vehicles Policies:
   ✅ 3 policies exactly:
      - user_vehicles_insert_policy
      - user_vehicles_select_policy
      - user_vehicles_delete_policy

4. Policy Count:
   ✅ vehicles: 4
   ✅ user_vehicles: 3

5. Duplicate Check:
   ✅ No results (no duplicates)

6. Foreign Keys:
   ✅ user_vehicles.user_id -> users.id
   ✅ user_vehicles.vehicle_id -> vehicles.id
```

### Step 4: Test in Your App
1. **Restart your Flutter app** (hot restart won't clear Supabase cache)
2. Test the following scenarios:

#### Test Scenario 1: Vehicle Creation
```
1. Create a new vehicle
2. Verify it appears in your vehicles list
3. Log in as a different user
4. Verify the vehicle does NOT appear
✅ Expected: Only the creator sees the vehicle
```

#### Test Scenario 2: Vehicle Sharing
```
1. Create a vehicle with User A
2. Share it with User B (if you have sharing UI)
3. Log in as User B
4. Verify User B can see the shared vehicle
✅ Expected: Shared vehicles are visible to recipients
```

#### Test Scenario 3: Vehicle Deletion
```
1. Create a vehicle
2. Delete it
3. Verify it's removed from your list
4. Log in as a different user
5. Verify they never saw it
✅ Expected: Deleted vehicles are gone for everyone
```

---

## What These Policies Do

### Vehicles Table (4 policies)

1. **INSERT** (`vehicles_insert_policy`)
   - Who: Any authenticated user
   - What: Can create new vehicles
   - Security: No restrictions (user_vehicles link handles ownership)

2. **SELECT** (`vehicles_select_policy`)
   - Who: Authenticated users
   - What: Can only see vehicles they have access to
   - Security: Enforced via `user_vehicles` join

3. **UPDATE** (`vehicles_update_policy`)
   - Who: Authenticated users
   - What: Can only update vehicles they have access to
   - Security: Enforced via `user_vehicles` join

4. **DELETE** (`vehicles_delete_policy`)
   - Who: Authenticated users
   - What: Can only delete vehicles they have access to
   - Security: Enforced via `user_vehicles` join

### User Vehicles Table (3 policies)

1. **INSERT** (`user_vehicles_insert_policy`)
   - Who: Authenticated users
   - What: Can only link vehicles to their own account
   - Security: Enforced via `users` table auth_id check

2. **SELECT** (`user_vehicles_select_policy`)
   - Who: Authenticated users
   - What: Can only see their own vehicle links
   - Security: Enforced via `users` table auth_id check

3. **DELETE** (`user_vehicles_delete_policy`)
   - Who: Authenticated users
   - What: Can only remove their own vehicle links
   - Security: Enforced via `users` table auth_id check

---

## Security Guarantees

✅ **Users can only see vehicles they have access to** (via `user_vehicles` table)
✅ **Users cannot see other users' vehicles** (enforced by SELECT policy)
✅ **Users cannot modify vehicles they don't have access to** (enforced by UPDATE/DELETE policies)
✅ **Users cannot link vehicles to other users' accounts** (enforced by INSERT policy)
✅ **No duplicate or conflicting policies** (clean migration drops all old policies)

---

## Troubleshooting

### Problem: Users still see all vehicles
**Solution:**
1. Verify the migration ran successfully (check SQL Editor for errors)
2. Run the verification script to check policy count
3. Clear your app's Supabase client cache (restart the app)
4. Check that `user_vehicles` table has correct entries for each user

### Problem: Users can't create vehicles
**Solution:**
1. Verify the `vehicles_insert_policy` exists (run verification script)
2. Check that the user is authenticated (not anonymous)
3. Review app logs for specific Supabase error messages

### Problem: Users can't see their own vehicles
**Solution:**
1. Verify the `user_vehicles` table has a row linking the user to the vehicle:
   ```sql
   SELECT * FROM user_vehicles 
   WHERE user_id IN (SELECT id FROM users WHERE auth_id = 'your-auth-uid');
   ```
2. Ensure your app creates the `user_vehicles` entry after creating a vehicle
3. Check the `VehicleProvider.addVehicle` method in your Flutter code

### Problem: Duplicate policy errors
**Solution:**
1. The cleanup migration drops ALL policies first, so this shouldn't happen
2. If it does, manually drop all policies in SQL Editor:
   ```sql
   DO $$ 
   DECLARE r RECORD;
   BEGIN
     FOR r IN (SELECT policyname FROM pg_policies WHERE tablename IN ('vehicles', 'user_vehicles'))
     LOOP
       EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON ' || quote_ident('vehicles');
       EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON ' || quote_ident('user_vehicles');
     END LOOP;
   END $$;
   ```
3. Then re-run the cleanup migration

---

## Next Steps

After applying the migration and verifying it works:

1. **Delete old migration files** (optional, for cleaner codebase):
   - `fix_rls_policies_final.sql`
   - `complete_database_fix.sql`
   - `setup_rls_policies.sql`
   - Any other RLS-related migrations

2. **Update your documentation** to reference only `cleanup_all_policies.sql` as the canonical RLS setup

3. **Commit the migration** to version control:
   ```bash
   git add supabase/migrations/cleanup_all_policies.sql
   git add supabase/migrations/verify_clean_policies.sql
   git commit -m "feat: comprehensive RLS policy cleanup and standardization"
   ```

4. **Consider adding vehicle sharing UI** (optional) to allow users to share vehicles with each other

---

## Questions?

If you encounter any issues:
1. Check the Supabase logs (Dashboard > Logs > Postgres Logs)
2. Run the verification script to diagnose the problem
3. Review the "Troubleshooting" section above
4. Check your Flutter app logs for specific Supabase error messages

---

**Status:** ✅ Ready to apply
**Files:** 
- `supabase/migrations/cleanup_all_policies.sql` (migration)
- `supabase/migrations/verify_clean_policies.sql` (verification)
- `supabase/migrations/MIGRATION_GUIDE.md` (this file)
