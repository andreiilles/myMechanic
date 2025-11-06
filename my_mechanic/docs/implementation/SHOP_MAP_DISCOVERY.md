# Shop Location & Map Discovery Implementation

## Overview
Implemented a map-based shop discovery system that allows customers to find nearby mechanic shops, view their details, and book appointments.

## Database Changes

### Mechanic Location Fields
Added two new columns to the `mechanics` table:
- `latitude` (DOUBLE PRECISION) - Shop's latitude coordinate
- `longitude` (DOUBLE PRECISION) - Shop's longitude coordinate

**Migration SQL**: See `docs/database/add_mechanic_location.sql`

```sql
ALTER TABLE mechanics
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
```

## Model Updates

### Mechanic Model
Updated `lib/models/mechanic.dart` to include:
- `final double? latitude`
- `final double? longitude`
- Updated `toJson()`, `fromJson()`, and `copyWith()` methods

## New Dependencies

Added to `pubspec.yaml`:
- `google_maps_flutter: ^2.5.3` - Google Maps integration
- `geolocator: ^11.0.0` - Device location services
- `geocoding: ^3.0.0` - Address geocoding

## New Screens

### 1. Find Shops Screen (`lib/screens/find_shops_screen.dart`)
**Purpose**: Interactive map showing all mechanic shop locations

**Features**:
- Google Maps with custom markers for shops
- Verified shops shown with green markers
- Unverified shops shown with red markers
- User's current location displayed
- Horizontal scrollable list of shops at bottom
- Tap marker or shop card to view details
- Auto-centering on user location or first shop

**Key Components**:
- `_getCurrentLocation()` - Requests and gets user's GPS location
- `_loadMechanics()` - Fetches all accepting mechanics from database
- `_createMarkers()` - Creates map markers for each shop
- `_onMarkerTapped()` - Shows detailed card for selected shop
- `_buildShopList()` - Horizontal scrollable shop cards
- `_buildSelectedShopCard()` - Detailed card with "View Details" button

### 2. Shop Detail Screen (`lib/screens/shop_detail_screen.dart`)
**Purpose**: Detailed view of a mechanic shop with booking capability

**Sections**:
1. **Header Card**
   - Business name
   - Verification badge
   - Star rating with review count
   - Accepting clients status (green/red indicator)

2. **Contact Information**
   - Address with location icon
   - Phone number with call icon
   - License number

3. **Services & Pricing**
   - Hourly rate
   - Specializations (as chips)

4. **About**
   - Business description

5. **Book Appointment Button**
   - Currently shows "coming soon" dialog
   - Ready for appointment system integration

## Provider Updates

### UserProvider (`lib/providers/user_provider.dart`)
Added new method:
```dart
Future<List<Mechanic>> loadAllMechanics()
```
- Fetches all mechanics accepting clients
- Orders by average rating (descending)
- Returns empty list on error

## Navigation Updates

### Main Screen (`lib/screens/main_screen.dart`)
**Customer tabs now include**:
1. Home
2. **Find Shops** (NEW)
3. Vehicles
4. Profile

**iOS Icons**:
- `CupertinoIcons.map` / `CupertinoIcons.map_fill`

**Android Icons**:
- `Icons.map_outlined` / `Icons.map`

## Platform Configuration Required

### Android (`android/app/src/main/AndroidManifest.xml`)
Add Google Maps API key:
```xml
<manifest>
  <application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_ANDROID_API_KEY_HERE"/>
  </application>
</manifest>
```

Add location permissions:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (`ios/Runner/AppDelegate.swift`)
Add Google Maps API key in `application` method:
```swift
GMSServices.provideAPIKey("YOUR_IOS_API_KEY_HERE")
```

Update `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to show nearby mechanic shops</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs your location to show nearby mechanic shops</string>
```

## User Flow

### For Customers:
1. Tap "Find Shops" tab in navigation
2. App requests location permission (first time)
3. Map loads showing nearby shops with markers
4. Browse shops via:
   - Tapping markers on map
   - Scrolling horizontal list at bottom
5. Selected shop shows detailed card
6. Tap "View Details" to see full shop information
7. Tap "Book Appointment" (coming soon feature)

### For Mechanics:
**To set shop location**:
1. Mechanics need to update their profile with latitude/longitude
2. Can be done through:
   - Direct database update
   - Future profile edit feature
   - External geocoding of business address

## Features

### Map View
- ✅ Interactive Google Maps
- ✅ Custom markers (color-coded by verification)
- ✅ User location tracking
- ✅ Info windows on markers
- ✅ Auto-centering
- ✅ Zoom controls

### Shop Cards
- ✅ Business name
- ✅ Verification badge
- ✅ Star rating
- ✅ Review count
- ✅ Address
- ✅ Phone number
- ✅ Operating status

### Filtering
- ✅ Only shows shops accepting clients
- ✅ Sorts by rating (highest first)

## Future Enhancements

1. **Search & Filters**
   - Search by shop name
   - Filter by specialization
   - Filter by rating
   - Distance-based filtering

2. **Appointment Booking**
   - Date/time selection
   - Service selection
   - Vehicle selection
   - Booking confirmation

3. **Directions**
   - Integration with Google Maps/Apple Maps
   - Turn-by-turn navigation
   - Estimated travel time

4. **Reviews & Photos**
   - Customer reviews
   - Shop photos
   - Service photos

5. **Advanced Features**
   - Shop availability calendar
   - Real-time waiting times
   - Price estimates
   - Promotional offers

## Testing Checklist

- [ ] Run SQL migration on database
- [ ] Add Google Maps API keys for Android/iOS
- [ ] Configure location permissions
- [ ] Add test mechanics with latitude/longitude
- [ ] Test location permission request
- [ ] Test map loading
- [ ] Test marker interactions
- [ ] Test shop card selection
- [ ] Test shop detail navigation
- [ ] Test on both iOS and Android

## Notes

- Google Maps API key required (costs may apply)
- Location permissions must be granted by user
- Mechanics without coordinates won't appear on map
- Geocoding can convert addresses to coordinates
- Consider adding automatic geocoding for addresses
- Consider caching map data for offline viewing

## Related Files

- `lib/models/mechanic.dart` - Updated model
- `lib/screens/find_shops_screen.dart` - Map view
- `lib/screens/shop_detail_screen.dart` - Detail view
- `lib/screens/main_screen.dart` - Navigation
- `lib/providers/user_provider.dart` - Data provider
- `docs/database/add_mechanic_location.sql` - Migration

## Last Updated
November 6, 2025
