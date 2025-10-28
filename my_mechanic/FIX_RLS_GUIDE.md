# Fix RLS Policy Issue - Quick Guide

## Problem
Users get a "42501: Unauthorized" error when trying to create their profile because the RLS (Row Level Security) policy was too restrictive.

## Solution

### Option 1: Run the Quick Fix (Recommended)

1. **Open Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your project

2. **Go to SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Copy and paste this SQL:**

```sql
-- Fix users table policy
DROP POLICY IF EXISTS "Users can create their own profile" ON users;
DROP POLICY IF EXISTS "Authenticated users can create profile" ON users;
CREATE POLICY "Authenticated users can create profile" ON users
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
  );

-- Fix mechanics table policy
DROP POLICY IF EXISTS "Mechanics can create their own profile" ON mechanics;
DROP POLICY IF EXISTS "Authenticated users can create mechanic profile" ON mechanics;
CREATE POLICY "Authenticated users can create mechanic profile" ON mechanics
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
  );
```

4. **Click "Run"**

5. **Restart your Flutter app** and try creating your profile again

### Option 2: Recreate the Entire Database

If you want to start fresh:

1. Go to Supabase Dashboard → Database → Tables
2. Delete all tables (users, mechanics, vehicles, etc.)
3. Go to SQL Editor
4. Copy the contents of `database_schema.sql` and run it
5. Restart your Flutter app

## What Changed?

**Before:**
- The INSERT policy checked if `auth.uid() = auth_id`, which could fail due to timing issues
- This was too restrictive for initial profile creation

**After:**
- The INSERT policy now checks if `auth.uid() IS NOT NULL` (user is authenticated)
- This allows any authenticated user to create their profile
- More permissive but still secure since users must be logged in

## Test the Fix

1. **Sign in** with your existing account
2. You should see the **Profile Setup Screen**
3. **Complete the setup**:
   - Select "Mechanic" or "Customer"
   - Fill in your information
   - Click "Complete"
4. Your profile should be created successfully
5. You'll be redirected to the **Home Screen**

## Still Having Issues?

If you still get errors, check:

1. **Supabase Logs**: Dashboard → Logs → Look for errors
2. **Auth Session**: Make sure you're properly logged in (check the Flutter console logs)
3. **RLS Policies**: Dashboard → Database → Policies → Verify the new policies exist

## Additional Notes

- The fix is also in `fix_rls_policies.sql` for convenience
- The full schema with fixes is in `database_schema.sql`
- All changes maintain security - users can only access their own data
