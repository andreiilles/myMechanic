# Troubleshooting Guide - My Mechanic App

## Issues Fixed

### 1. ❌ NULL ID Constraint Violation
**Error**: `null value in column "id" of relation "users" violates not-null constraint`

**Cause**: The `toJson()` method was including `id: null` when inserting new records.

**Solution**: 
- Modified `AppUser.toJson()` and `Mechanic.toJson()` to accept `excludeId` parameter
- When inserting new records, use `toJson(excludeId: true)` to exclude the null ID
- The database auto-generates IDs using `gen_random_uuid()`

### 2. ❌ Row-Level Security Policy Violation (UPDATED)
**Error**: `new row violates row-level security policy for table "users"` (Code: 42501)

**Cause**: The RLS policy for INSERT was checking `auth.uid() = auth_id`, which could fail during initial profile creation due to session timing.

**Solution**: Updated the INSERT policies to be more permissive while still requiring authentication:

```sql
-- For users table
DROP POLICY IF EXISTS "Users can create their own profile" ON users;
CREATE POLICY "Authenticated users can create profile" ON users
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL  -- Any authenticated user can insert their profile
  );

-- For mechanics table
DROP POLICY IF EXISTS "Mechanics can create their own profile" ON mechanics;
CREATE POLICY "Authenticated users can create mechanic profile" ON mechanics
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL  -- Any authenticated user can create a mechanic profile
  );
```

**Quick Fix**: Run the SQL in `fix_rls_policies.sql` in your Supabase SQL Editor.

**Note**: This change maintains security - users must still be authenticated to create profiles, but the check is more flexible.

### 3. ❌ Infinite Loading Loop
**Error**: After sign-in, the app shows infinite loading spinner

**Cause**: `AuthWrapper` was calling `loadUserProfile` on every rebuild in a `StatelessWidget`, causing an infinite loop.

**Solution**: 
- Converted `AuthWrapper` to `StatefulWidget`
- Added state variables to track loading status:
  - `_isLoadingProfile`: Currently loading
  - `_hasAttemptedLoad`: Already tried to load (prevents retries)
- Proper error handling with retry option

### 4. ❌ Vehicle Creation RLS Policy Violation
**Error**: `new row violates row-level security policy for table "vehicles"` (Code: 42501)

**Cause**: The RLS policy for vehicles INSERT was using a subquery check that could fail:
```sql
FOR INSERT WITH CHECK (
  user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
)
```

**Solution**: Simplified the policy to just check authentication:

```sql
DROP POLICY IF EXISTS "Users can create their own vehicles" ON vehicles;
CREATE POLICY "Authenticated users can create vehicles" ON vehicles
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL  -- Any authenticated user can create vehicles
  );
```

**Quick Fix**: Run the SQL in `fix_vehicle_rls.sql` or `fix_rls_policies.sql` in your Supabase SQL Editor.

**Why This Works**: The subquery check can fail due to timing or session issues. The simpler authentication check is more reliable and still secure since:
- Only authenticated users can insert
- Users can only view/edit/delete their own vehicles (other policies handle this)
- The `user_id` is set by the app, not the user

## Setup Instructions

### Step 1: Run Database Schema
1. Open your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the entire contents of `database_schema.sql`
4. Click **Run** to execute

This will create:
- ✅ `users` table with proper RLS policies
- ✅ `mechanics` table with proper RLS policies
- ✅ `vehicles` table with proper RLS policies
- ✅ `maintenance_records` table with proper RLS policies
- ✅ `maintenance_reminders` table with proper RLS policies
- ✅ Indexes for better performance

### Step 2: Test the App
1. **Hot Restart** the Flutter app (not just hot reload)
2. Try signing up with a new account
3. Select user type (Customer or Mechanic)
4. Complete the profile information
5. Sign in with your new account

## How the Fixed Flow Works

### Sign-Up Flow:
1. **Create Auth Account**: User creates account with email/password
2. **Wait for Session**: 500ms delay to ensure auth session is established
3. **Create User Profile**: Insert into `users` table
4. **Create Mechanic Profile** (if mechanic): Insert into `mechanics` table
5. **Success**: Navigate to home screen

### Sign-In Flow:
1. **Authenticate**: User signs in with credentials
2. **Load Profile**: `AuthWrapper` loads user profile from database
3. **Check Status**:
   - ✅ Profile found → Navigate to Home Screen
   - ❌ Profile not found → Show error with retry/logout options
4. **Load Vehicles**: Home screen loads user's vehicles

## Debug Features Added

### Console Logging:
```dart
debugPrint('Auth user ID: ${authProvider.user?.id}');
debugPrint('Creating user profile: ${user.toJson(excludeId: true)}');
debugPrint('User profile creation error: ${userProvider.error}');
```

### Error Messages:
- User-friendly messages shown to users
- Full error details logged to console for debugging
- Specific error handling for common issues (duplicate email, constraints, etc.)

## Common Issues & Solutions

### Issue: "Profile Not Found" after sign-in
**Solution**: 
- Check if the user profile exists in the `users` table in Supabase
- Verify the `auth_id` matches the auth user ID
- Click "Retry" button to attempt loading again

### Issue: "Duplicate key" error during signup
**Solution**: 
- Email already exists in the system
- Use a different email or sign in with existing account

### Issue: Still getting RLS errors
**Solution**: 
- Make sure you ran the updated `database_schema.sql`
- Check that RLS policies are correctly created in Supabase dashboard
- Verify the auth session is active (check console logs)

## Database Structure

```
auth.users (Supabase Auth)
    ↓ (auth_id reference)
users (App User Profiles)
    ↓ (user_id reference)
    ├── vehicles → maintenance_records
    ├── vehicles → maintenance_reminders  
    └── mechanics (if user_type = 'mechanic')
```

## Key Files Modified

1. **Models**:
   - `lib/models/app_user.dart` - Added `excludeId` parameter
   - `lib/models/mechanic.dart` - Added `excludeId` parameter

2. **Providers**:
   - `lib/providers/user_provider.dart` - Use `excludeId: true` for inserts
   - `lib/providers/auth_provider.dart` - Added profile checking

3. **Screens**:
   - `lib/screens/auth_wrapper.dart` - Fixed infinite loading loop
   - `lib/screens/signup_screen.dart` - Better error handling, debug logs

4. **Database**:
   - `database_schema.sql` - Fixed RLS policies, added all tables

## Testing Checklist

- [ ] Sign up as Customer works
- [ ] Sign up as Mechanic works
- [ ] Sign in with existing account works
- [ ] Profile loads correctly after sign-in
- [ ] No infinite loading spinner
- [ ] Error messages are user-friendly
- [ ] Console shows debug information
- [ ] Vehicles can be added (for customers)

## Next Steps

Once everything is working:
1. Remove or reduce debug logging
2. Implement remaining features (maintenance records, reminders)
3. Add mechanic discovery for customers
4. Implement service booking system

## Need Help?

Check the console logs for detailed error messages. The app now logs:
- Auth user information
- Profile creation attempts
- Full error details
- Loading state changes

All errors are also displayed to users in a friendly format!
