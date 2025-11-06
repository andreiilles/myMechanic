# Widget Index - myMechanic

## Overview
This file provides an index of all modular widgets in the myMechanic application.

## Vehicle Detail Widgets
Location: `lib/widgets/vehicle_detail/`

### VehicleHeader
**File:** `vehicle_header.dart`
- Displays vehicle image, make, model, year, and license plate
- Includes hero animation for image
- Handles image tap callback

**Usage:**
```dart
VehicleHeader(
  vehicle: vehicle,
  onImageTap: () => showImagePicker(),
)
```

### VehicleInfoCard
**File:** `vehicle_info_widgets.dart`
- Generic card container for displaying information
- Used throughout the vehicle detail screen

**Usage:**
```dart
VehicleInfoCard(
  children: [
    VehicleInfoRow(label: 'Make', value: 'Toyota'),
    VehicleInfoRow(label: 'Model', value: 'Camry'),
  ],
)
```

### VehicleInfoRow
**File:** `vehicle_info_widgets.dart`
- Displays a label-value pair
- Optional icon support

**Usage:**
```dart
VehicleInfoRow(
  label: 'VIN',
  value: '1HGBH41JXMN109186',
  icon: Icons.info,
)
```

### VehicleStatCard
**File:** `vehicle_info_widgets.dart`
- Displays a statistic with icon
- Customizable color

**Usage:**
```dart
VehicleStatCard(
  title: 'Services',
  value: '12',
  icon: Icons.build,
  color: Colors.blue,
)
```

### VehicleOverviewTab
**File:** `vehicle_overview_tab.dart`
- Complete overview tab content
- Shows vehicle info, mileage, stats, and shared users
- Integrates with VehicleProvider and MaintenanceProvider

**Usage:**
```dart
VehicleOverviewTab(vehicle: vehicle)
```

### VehicleMaintenanceTab
**File:** `vehicle_maintenance_tab.dart`
- Complete maintenance tab content
- Lists all maintenance records
- Handles empty state and add button

**Usage:**
```dart
VehicleMaintenanceTab(vehicle: vehicle)
```

### MaintenanceRecordCard
**File:** `vehicle_maintenance_tab.dart`
- Individual maintenance record display
- Shows service type, date, mileage, cost, and description

**Usage:**
```dart
MaintenanceRecordCard(record: maintenanceRecord)
```

### VehicleDocumentsTab
**File:** `vehicle_documents_tab.dart`
- Placeholder for documents feature
- Shows empty state

**Usage:**
```dart
VehicleDocumentsTab()
```

## Sign Up Widgets
Location: `lib/widgets/signup/`

### SignUpAuthStep
**File:** `signup_auth_step.dart`
- Email and password input step
- Password visibility toggles
- Email validation

**Usage:**
```dart
SignUpAuthStep(
  emailController: _emailController,
  passwordController: _passwordController,
  confirmPasswordController: _confirmPasswordController,
  obscurePassword: _obscurePassword,
  obscureConfirmPassword: _obscureConfirmPassword,
  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
  onToggleConfirmPassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
)
```

### SignUpUserTypeStep
**File:** `signup_user_type_step.dart`
- User type selection (Customer or Mechanic)
- Visual card-based selection

**Usage:**
```dart
SignUpUserTypeStep(
  selectedUserType: _selectedUserType,
  onUserTypeSelected: (type) => setState(() => _selectedUserType = type),
)
```

### UserTypeCard
**File:** `signup_user_type_step.dart`
- Individual user type selection card
- Shows icon, title, description
- Highlights when selected

**Usage:**
```dart
UserTypeCard(
  userType: UserType.customer,
  title: 'Vehicle Owner',
  description: 'I want to track my vehicle\'s maintenance',
  icon: Icons.directions_car,
  isSelected: selectedUserType == UserType.customer,
  onTap: () => onUserTypeSelected(UserType.customer),
)
```

### SignUpUserInfoStep
**File:** `signup_user_info_step.dart`
- Personal information input
- First name, last name, phone number

**Usage:**
```dart
SignUpUserInfoStep(
  firstNameController: _firstNameController,
  lastNameController: _lastNameController,
  phoneController: _phoneController,
)
```

### SignUpMechanicInfoStep
**File:** `signup_mechanic_info_step.dart`
- Mechanic business information
- Business name, address, license, rate, description

**Usage:**
```dart
SignUpMechanicInfoStep(
  businessNameController: _businessNameController,
  businessAddressController: _businessAddressController,
  licenseNumberController: _licenseNumberController,
  hourlyRateController: _hourlyRateController,
  descriptionController: _descriptionController,
)
```

## Best Practices

### Widget Design
1. **Single Responsibility**: Each widget has one clear purpose
2. **Composition**: Build complex UIs from simple widgets
3. **Reusability**: Design widgets to be used in multiple places
4. **Testability**: Keep widgets stateless when possible

### Parameter Passing
1. **Required vs Optional**: Use required for essential parameters
2. **Callbacks**: Use VoidCallback, ValueChanged<T>, or custom callbacks
3. **Controllers**: Pass TextEditingControllers for form fields
4. **Models**: Pass complete model objects instead of individual fields

### State Management
1. **Stateless Preferred**: Use StatelessWidget when possible
2. **Local State**: Keep state local to the widget when possible
3. **Provider**: Use Provider for shared state
4. **Callbacks**: Use callbacks to bubble events up

### File Organization
```
lib/
├── widgets/
│   ├── feature_name/
│   │   ├── feature_component1.dart
│   │   ├── feature_component2.dart
│   │   └── feature_component3.dart
│   └── another_feature/
│       └── ...
```

## Adding New Widgets

### Steps
1. Identify the feature area (e.g., vehicle_detail, signup)
2. Create or use existing feature folder in `lib/widgets/`
3. Create widget file with clear, descriptive name
4. Implement widget following Single Responsibility Principle
5. Export from feature folder if needed
6. Update this index

### Naming Convention
- **Files**: `feature_component.dart` (snake_case)
- **Classes**: `FeatureComponent` (PascalCase)
- **Private methods**: `_methodName` (camelCase with underscore)

### Template
```dart
import 'package:flutter/material.dart';

/// Brief description of what this widget does.
///
/// Longer description if needed, including:
/// - Key features
/// - When to use it
/// - Important parameters
class FeatureComponent extends StatelessWidget {
  /// Description of this parameter
  final String requiredParameter;
  
  /// Optional parameter description
  final String? optionalParameter;
  
  /// Callback description
  final VoidCallback? onTap;

  const FeatureComponent({
    super.key,
    required this.requiredParameter,
    this.optionalParameter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

## Future Widgets to Extract

### High Priority
1. **AddMaintenanceForm** - Extract from `add_maintenance_screen.dart`
2. **ProfileSetupSteps** - Extract from `profile_setup_screen.dart`
3. **HomeScreenSections** - Extract dashboard widgets from `home_screen.dart`

### Medium Priority
4. **VehicleFormFields** - Extract from `add_vehicle_screen.dart`
5. **ShopManagementWidgets** - Extract from `my_shop_screen.dart`
6. **ShareVehicleComponents** - Split `share_vehicle_dialog.dart`

## Testing

### Unit Testing Widgets
```dart
testWidgets('VehicleHeader displays vehicle information', (tester) async {
  final vehicle = Vehicle(/* ... */);
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VehicleHeader(
          vehicle: vehicle,
          onImageTap: () {},
        ),
      ),
    ),
  );
  
  expect(find.text('${vehicle.make} ${vehicle.model}'), findsOneWidget);
});
```

## Documentation

Each widget should have:
1. **Class documentation**: What the widget does
2. **Parameter documentation**: What each parameter is for
3. **Usage example**: How to use the widget
4. **Entry in this index**: Reference for developers

## Maintenance

This index should be updated when:
- New widgets are added
- Widgets are renamed or moved
- Widget APIs change significantly
- Best practices are updated
