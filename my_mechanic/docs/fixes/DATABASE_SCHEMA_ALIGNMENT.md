# Database Schema Alignment Fix

## Problem
The application code was referencing a `user_vehicles` junction table that doesn't exist in the actual database. This caused runtime errors when trying to load or create vehicles.

**Error Message:**
```
Could not find the table 'public.user_vehicles' in the schema cache
```

## Root Cause
The code was designed with a different database schema than what was actually implemented:

### Expected Schema (Old Code)
- `vehicles` table with `user_id` field
- `user_vehicles` junction table to manage many-to-many relationships
- `relationship` field to describe connection (owner, family_member, shared)

### Actual Schema (Database)
- `vehicles` table with `owner_id` field (UUID, foreign key to `users.id`)
- `vehicle_access` table for shared access management
- `access_level` field with values: 'view', 'edit', 'owner'
- `granted_by` field to track who granted access

## Solution
Updated all code references to match the actual database schema:

### 1. Vehicle Model (`lib/models/vehicle.dart`)
- ✅ Changed `userId` field to `ownerId`
- ✅ Updated `toJson()` to serialize `owner_id`
- ✅ Updated `fromJson()` to deserialize `owner_id`
- ✅ Updated `copyWith()` to handle `ownerId`

### 2. Vehicle Provider (`lib/providers/vehicle_provider.dart`)

#### `loadVehicles()` Method
**Before:**
```dart
// Queried user_vehicles junction table
final response = await SupabaseService.client
    .from('user_vehicles')
    .select('vehicle_id')
    .eq('user_id', userId);
```

**After:**
```dart
// Query owned vehicles directly
final ownedVehiclesResponse = await SupabaseService.client
    .from('vehicles')
    .select()
    .eq('owner_id', userId);

// Query shared access separately
final sharedAccessResponse = await SupabaseService.client
    .from('vehicle_access')
    .select('vehicle_id')
    .eq('user_id', userId);
```

#### `addVehicle()` Method
**Before:**
- Checked for existing vehicle by VIN
- Created links in `user_vehicles` table
- Verified trigger-created links
- ~200 lines of complex logic

**After:**
```dart
// Simplified: Just set owner_id when creating vehicle
final vehicleData = vehicle.toJson(excludeId: true);
vehicleData['owner_id'] = userId;

await SupabaseService.client
    .from('vehicles')
    .insert(vehicleData)
    .select()
    .single();
```

#### `unlinkVehicle()` Method
**Before:**
- Counted links in `user_vehicles`
- Deleted vehicle if last link

**After:**
- Check if user is owner via `owner_id`
- Check `vehicle_access` for shared users
- Owners can only delete if not shared
- Non-owners remove their `vehicle_access` entry

#### `isVehicleShared()` Method
**Before:**
```dart
// Counted user_vehicles links
return (userLinks as List).length > 1;
```

**After:**
```dart
// Check if vehicle_access has any entries
final sharedAccess = await SupabaseService.client
    .from('vehicle_access')
    .select()
    .eq('vehicle_id', vehicleId);
return (sharedAccess as List).isNotEmpty;
```

#### `getVehicleUsers()` Method
**Before:**
```dart
// Queried user_vehicles with join
.from('user_vehicles')
.select('user_id, relationship, users(...)')
```

**After:**
```dart
// Get owner from vehicles table
final vehicle = await SupabaseService.client
    .from('vehicles')
    .select('owner_id, users!vehicles_owner_id_fkey(...)')
    .eq('id', vehicleId)
    .single();

// Get shared access from vehicle_access
final sharedAccess = await SupabaseService.client
    .from('vehicle_access')
    .select('user_id, access_level, users(...)')
    .eq('vehicle_id', vehicleId);
```

### 3. Share Vehicle Dialog (`lib/widgets/share_vehicle_dialog.dart`)

**Changed:**
- Variable name: `_selectedRelationship` → `_selectedAccessLevel`
- Default value: `'family_member'` → `'edit'`
- Table name: `user_vehicles` → `vehicle_access`
- Field name: `relationship` → `access_level`
- Added `granted_by` field when creating access

**UI Updates:**
- Label: "Relationship" → "Access Level"
- Options: "Family / Friend" → "View Only / Can Edit"
- Added check for authenticated user before sharing

## Database Schema Reference

### vehicles Table
```sql
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES users(id),
  make TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER NOT NULL,
  vin TEXT UNIQUE NOT NULL,
  current_mileage INTEGER NOT NULL,
  license_plate TEXT,
  image_url TEXT,
  last_technical_inspection TIMESTAMP,
  next_technical_inspection TIMESTAMP,
  inspection_interval_description TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### vehicle_access Table
```sql
CREATE TABLE vehicle_access (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  access_level TEXT NOT NULL CHECK (access_level IN ('view', 'edit', 'owner')),
  granted_by UUID REFERENCES users(id),
  granted_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(vehicle_id, user_id)
);
```

## Testing Checklist
- [ ] Load vehicles for a user (owned + shared)
- [ ] Add a new vehicle (sets owner_id correctly)
- [ ] Share vehicle with another user (creates vehicle_access entry)
- [ ] View shared vehicle as non-owner
- [ ] Delete owned vehicle (checks for shared access)
- [ ] Remove shared access as non-owner
- [ ] Check RLS policies work correctly

## Next Steps
1. **Test vehicle creation** - Verify vehicles can be added with RLS enabled
2. **Configure RLS policies** - Set up proper policies for the new schema:
   ```sql
   -- Vehicles INSERT: Allow if setting owner_id to current user
   CREATE POLICY "Users can create vehicles they own"
     ON vehicles FOR INSERT
     WITH CHECK (owner_id = auth.uid());
   
   -- Vehicles SELECT: Allow if owner or has vehicle_access
   CREATE POLICY "Users can view owned or shared vehicles"
     ON vehicles FOR SELECT
     USING (
       owner_id = auth.uid() OR
       EXISTS (
         SELECT 1 FROM vehicle_access
         WHERE vehicle_id = vehicles.id
         AND user_id = auth.uid()
       )
     );
   
   -- Vehicles UPDATE: Allow owner or users with 'edit' access
   CREATE POLICY "Users can update vehicles they own or can edit"
     ON vehicles FOR UPDATE
     USING (
       owner_id = auth.uid() OR
       EXISTS (
         SELECT 1 FROM vehicle_access
         WHERE vehicle_id = vehicles.id
         AND user_id = auth.uid()
         AND access_level = 'edit'
       )
     );
   
   -- Vehicles DELETE: Only owner can delete
   CREATE POLICY "Only owners can delete vehicles"
     ON vehicles FOR DELETE
     USING (owner_id = auth.uid());
   ```

3. **Update documentation** - Revise vehicle sharing guides to reflect new schema
4. **Test sharing workflow** - Verify access levels work correctly

## Files Modified
- `lib/models/vehicle.dart` - Updated model fields
- `lib/providers/vehicle_provider.dart` - Rewrote all database queries
- `lib/widgets/share_vehicle_dialog.dart` - Updated sharing UI and logic

## Benefits of New Schema
1. **Clearer ownership** - `owner_id` field explicitly shows who owns the vehicle
2. **Better access control** - `access_level` enum provides clear permissions
3. **Audit trail** - `granted_by` tracks who shared the vehicle
4. **Simpler queries** - Direct foreign key instead of junction table
5. **Better performance** - Fewer joins for common operations
