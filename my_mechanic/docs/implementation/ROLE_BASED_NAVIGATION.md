# 🔧 Role-Based Navigation - Mechanic vs Customer

## Overview
The app now features different navigation tabs based on user role:
- **Customers**: See vehicle-focused tabs
- **Mechanics**: See business-focused tabs

## Navigation Structure

### 👤 Customer Navigation (3 Tabs)
1. **🏠 Home** - Dashboard with vehicles overview
2. **🚗 Vehicles** - Manage vehicles
3. **👤 Profile** - User settings

### 🔧 Mechanic Navigation (4 Tabs)
1. **🏠 Home** - Dashboard with business overview  
2. **🏢 My Shop** - Business information and settings
3. **📅 Appointments** - Manage customer appointments
4. **👤 Profile** - User settings

## New Screens Created

### 1. My Shop Screen (`my_shop_screen.dart`)
**For**: Mechanics only

**Features**:
- **Business Information Card**
  - Business name
  - Verification badge (if verified)
  - Address
  - License number
  - Hourly rate

- **Rating & Reviews Card**
  - Average rating (stars)
  - Total number of reviews

- **About Section**
  - Business description

- **Edit Button**
  - Opens shop info editor (TODO)

**Design**:
- Platform-adaptive (Cupertino on iOS, Material on Android)
- Card-based layout
- Professional business presentation

### 2. Appointments Screen (`appointments_screen.dart`)
**For**: Mechanics only

**Features**:
- **Filter Chips**
  - All appointments
  - Pending
  - Confirmed
  - Completed

- **Appointments List**
  - Customer information
  - Vehicle details
  - Date & time
  - Status

**Current State**: Empty state placeholder
- Shows "No appointments yet" message
- Ready for appointment data integration

## How It Works

### Role Detection
```dart
final userProvider = context.watch<UserProvider>();
final isMechanic = userProvider.currentUser?.userType == UserType.mechanic;
```

### Dynamic Tab Lists
```dart
// Customer: 3 tabs
final customerScreens = [HomeScreen(), VehiclesScreen(), ProfileScreen()];

// Mechanic: 4 tabs
final mechanicScreens = [HomeScreen(), MyShopScreen(), AppointmentsScreen(), ProfileScreen()];

final screens = isMechanic ? mechanicScreens : customerScreens;
```

### Platform-Specific Icons

#### iOS (Cupertino)
**Customer**:
- Home: `house_fill`
- Vehicles: `car_fill`
- Profile: `person_fill`

**Mechanic**:
- Home: `house_fill`
- My Shop: `briefcase_fill`
- Appointments: `calendar_badge_plus`
- Profile: `person_fill`

#### Android (Material)
**Customer**:
- Home: `home`
- Vehicles: `directions_car`
- Profile: `person`

**Mechanic**:
- Home: `home`
- My Shop: `business`
- Appointments: `event_note`
- Profile: `person`

## File Structure

```
lib/screens/
├── main_screen.dart          ← Updated with role-based navigation
├── home_screen.dart          ← Shared by both roles
├── vehicles_screen.dart      ← Customer only (via general tab)
├── my_shop_screen.dart       ← NEW: Mechanic only
├── appointments_screen.dart  ← NEW: Mechanic only
└── profile_screen.dart       ← Shared by both roles
```

## User Experience

### For Customers
When a customer logs in:
1. Sees 3 tabs at the bottom
2. Can manage their vehicles
3. Can view and edit their profile
4. Vehicle-centric experience

### For Mechanics
When a mechanic logs in:
1. Sees 4 tabs at the bottom
2. Can view/edit shop information
3. Can manage appointments
4. Can view and edit their profile
5. Business-centric experience

## Future Enhancements

### My Shop Screen
- [ ] Edit shop information
- [ ] Upload shop photos
- [ ] Manage specializations
- [ ] Set working hours
- [ ] Configure services offered
- [ ] Pricing management

### Appointments Screen
- [ ] Real appointment data integration
- [ ] Accept/decline appointments
- [ ] View appointment details
- [ ] Customer contact information
- [ ] Service history per customer
- [ ] Appointment notifications
- [ ] Calendar view
- [ ] Time slot management

### Both Roles
- [ ] In-app messaging
- [ ] Notifications
- [ ] Payment integration
- [ ] Review system

## Testing

### Test as Customer
1. Sign up as customer
2. Complete profile
3. See 3-tab navigation
4. Access Home, Vehicles, Profile

### Test as Mechanic
1. Sign up as mechanic
2. Complete profile (including business info)
3. See 4-tab navigation
4. Access Home, My Shop, Appointments, Profile

## Benefits

✅ **Role-Appropriate UX**: Each user sees only relevant features
✅ **Scalable**: Easy to add more role-specific features
✅ **Maintainable**: Clear separation of concerns
✅ **Platform-Native**: Adapts to iOS and Android design languages
✅ **Professional**: Proper business tools for mechanics

## Notes

- The navigation automatically adjusts based on `UserType` enum
- Both customer and mechanic access the same `HomeScreen` (can be customized later)
- Profile screen is shared between roles (can show role-specific settings)
- All screens are fully platform-adaptive (iOS/Android)
