# Database Update Required - Shop Editing Fix

## Problem
The shop editing feature is failing because the `mechanics` table is missing several columns that the app expects.

## Missing Columns
- `business_phone` - Shop contact number
- `latitude` - Map coordinate
- `longitude` - Map coordinate  
- `is_accepting_clients` - Availability status
- `average_rating` - Customer ratings (may be named `rating` in old schema)
- `total_reviews` - Review count

## Quick Fix (Easiest Method)

### Option 1: Using Supabase SQL Editor (Recommended)

1. **Open Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project

2. **Open SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Run the Migration**
   - Copy the entire contents of `QUICK_FIX_MECHANICS_TABLE.sql`
   - Paste it into the SQL editor
   - Click "Run" button

4. **Verify Success**
   - You should see a table showing all the columns in the `mechanics` table
   - Make sure these columns exist:
     - `business_phone`
     - `latitude`
     - `longitude`
     - `is_accepting_clients`
     - `average_rating`
     - `total_reviews`

5. **Test the App**
   - Restart your Flutter app
   - Go to "My Shop" section (as a mechanic)
   - Click "Edit Shop Info"
   - Try saving changes - should now work! ✅

### Option 2: Using Supabase CLI

If you have Supabase CLI installed:

```bash
cd /Users/andreiilles/Cod/Flutter/myMechanic/my_mechanic

# Make the script executable
chmod +x scripts/apply_mechanic_fields_migration.sh

# Run the migration script
./scripts/apply_mechanic_fields_migration.sh
```

### Option 3: Manual Migration

If you prefer, you can manually run the migration:

```bash
cd /Users/andreiilles/Cod/Flutter/myMechanic/my_mechanic
supabase db push
```

## What Gets Added

### New Columns
```sql
business_phone       TEXT              -- Shop phone number
latitude            DOUBLE PRECISION   -- Location coordinate
longitude           DOUBLE PRECISION   -- Location coordinate
is_accepting_clients BOOLEAN           -- Default: TRUE
average_rating      DECIMAL(3,2)      -- Default: 0.00
total_reviews       INTEGER           -- Default: 0
```

### Indexes for Performance
- `idx_mechanics_location` - Fast location queries for map
- `idx_mechanics_accepting` - Quick filter for available shops

## After Migration

Once you've run the migration:

1. ✅ Shop editing will work without errors
2. ✅ Location/address can be saved
3. ✅ Phone number can be added
4. ✅ "Accepting clients" toggle will work
5. ✅ Shops will appear on the Find Shops map (when API key is configured)

## Troubleshooting

### Still Getting Errors?

1. **Check column names in error message**
   - Look at the Flutter console/logs
   - Note which column is causing the issue

2. **Verify columns exist**
   ```sql
   SELECT column_name 
   FROM information_schema.columns
   WHERE table_name = 'mechanics';
   ```

3. **Check for typos**
   - `average_rating` not `averageRating`
   - `is_accepting_clients` not `isAcceptingClients`
   - Database uses snake_case, Flutter uses camelCase

4. **Clear app cache**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Migration Already Applied?

If you get "column already exists" errors, that's fine! The migration uses `IF NOT EXISTS` so it's safe to run multiple times.

## Need Help?

If you're still having issues:

1. Check the Flutter console for specific error messages
2. Look at the Supabase logs in the dashboard
3. Verify your Mechanic model in `lib/models/mechanic.dart` matches the database columns

## Files in This Fix

- `QUICK_FIX_MECHANICS_TABLE.sql` - Run this in Supabase SQL Editor
- `supabase/migrations/20251106_add_mechanic_fields.sql` - Proper migration file
- `scripts/apply_mechanic_fields_migration.sh` - Automated script (requires Supabase CLI)
- `DATABASE_FIX_GUIDE.md` - This guide
