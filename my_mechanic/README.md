# My Mechanic - Car Maintenance Tracker

A Flutter app to help users manage their car maintenance, track service history, and receive reminders for important maintenance tasks.

## 📚 Documentation

**All documentation has been organized into the [`docs/`](docs/) directory.**

### Quick Links
- 📖 **[Documentation Index](docs/INDEX.md)** - Complete visual guide to all documentation
- 🚀 **[Quick Navigation](docs/QUICK_NAV.md)** - Fast access to common resources
- 📋 **[Documentation README](docs/README.md)** - Overview and organization

### Documentation Categories

| Category | Location | Description |
|----------|----------|-------------|
| 🔧 **Implementation** | [`docs/implementation/`](docs/implementation/) | Feature implementation guides (Vehicle management, Image upload, UI, etc.) |
| 🐛 **Bug Fixes** | [`docs/fixes/`](docs/fixes/) | Documentation for resolved issues and patches |
| 🔍 **Troubleshooting** | [`docs/troubleshooting/`](docs/troubleshooting/) | Problem-solving guides and error resolution |
| 💾 **Database** | [`docs/database/`](docs/database/) | Database schema, migrations, and SQL scripts |
| 📚 **Guides** | [`docs/guides/`](docs/guides/) | Quick reference guides and best practices |

### Key Documents
- [Vehicle Details Implementation](docs/implementation/VEHICLE_DETAIL_IMPLEMENTATION.md)
- [Vehicle Sharing System](docs/implementation/VEHICLE_SHARING_IMPLEMENTATION.md)
- [Image Upload Guide](docs/implementation/IMAGE_UPLOAD_SUMMARY.md)
- [Platform Adaptive UI](docs/implementation/PLATFORM_ADAPTIVE_UI.md)
- [RLS Security Guide](docs/guides/FIX_RLS_GUIDE.md)
- [General Troubleshooting](docs/troubleshooting/TROUBLESHOOTING.md)

## Features

- **User Authentication**: Secure login and registration using Supabase Auth with email confirmation
- **User Roles**: Separate experiences for Customers (vehicle owners) and Mechanics
- **Profile Management**: Complete user profiles with editable information
- **Vehicle Management**: Add, view, edit, and manage multiple vehicles with images
- **Vehicle Sharing**: Share vehicle access with mechanics or other users
- **Technical Inspections**: Track Romanian ITP inspections with automatic date calculations
- **Maintenance Records**: Track all maintenance activities with detailed information
- **Maintenance Reminders**: Set date or mileage-based reminders
- **Service History**: View complete maintenance history for each vehicle
- **Platform Adaptive UI**: Native iOS (Cupertino) and Android (Material) design
- **Image Upload**: Vehicle photos stored in Supabase storage
- **Push Notifications**: Local notifications for maintenance reminders (planned)

## Use Cases Implemented

1. ✅ **Register/Login**: User authentication with email/password and email confirmation
2. ✅ **User Role Selection**: Choose between Customer (vehicle owner) or Mechanic during signup
3. ✅ **Profile Creation**: Complete user profile with personal/business information
4. ✅ **Profile Management**: Edit user profile information (name, phone, etc.)
5. ✅ **Add Vehicle**: Add vehicles with VIN, make, model, year, mileage, images, etc.
6. ✅ **View Vehicles**: Display list of registered vehicles with images
7. ✅ **Edit Vehicle**: Update vehicle information and images
8. ✅ **Vehicle Sharing**: Share vehicle access with other users (mechanics, family)
9. ✅ **Technical Inspection Tracking**: Romanian ITP inspection tracking with auto-calculation
10. ✅ **Add Maintenance Record**: Track maintenance activities
11. ✅ **View Maintenance History**: Display service history
12. ✅ **Platform Adaptive UI**: Native iOS and Android designs
13. ✅ **Mechanic Profile**: Business profile for mechanics with shop information
14. ✅ **Appointments System**: View appointments for mechanics (UI complete)
15. 🔄 **Set Maintenance Reminder**: Create alerts for future maintenance (In Progress)
16. 🔄 **Receive Reminder Notification**: Push notifications (Planned)
17. 🔄 **Edit/Delete Maintenance Record**: Modify existing records (Planned)
18. ✅ **Logout**: User can sign out with proper data clearing

## Technology Stack

- **Flutter**: Cross-platform mobile framework (iOS & Android)
- **Dart**: Programming language
- **Supabase**: Backend-as-a-Service
  - Authentication with email confirmation
  - PostgreSQL database with Row Level Security (RLS)
  - Storage for vehicle images
  - Real-time subscriptions
- **Provider**: State management pattern
- **SharedPreferences**: Local data persistence
- **Image Picker**: Camera and gallery access
- **Google Fonts**: Typography
- **Email Validator**: Email validation
- **Flutter Local Notifications**: Push notifications (planned)

## Prerequisites

- Flutter SDK (3.9.2+)
- Dart SDK
- Supabase account
- VS Code or Android Studio

## Setup Instructions

### 1. Supabase Configuration

1. Create a new project on [Supabase](https://supabase.com)
2. Get your project URL and anon key from the project settings
3. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```
4. Update the `.env` file with your Supabase credentials:
   ```env
   SUPABASE_URL=your_supabase_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```

### 2. Database Schema

**Note**: Complete database schema and SQL scripts are available in [`docs/database/`](docs/database/).

The main SQL schema file is at [`docs/database/database_schema.sql`](docs/database/database_schema.sql).

Key tables include:
- `users` - User profiles (customers and mechanics)
- `mechanics` - Extended mechanic business information
- `vehicles` - Vehicle information with images
- `vehicle_sharing` - Vehicle access sharing system
- `maintenance_records` - Service history
- `maintenance_reminders` - Maintenance alerts

For detailed setup instructions and migration guides, see:
- [Database Documentation](docs/database/)
- [Migration Guide](docs/database/MIGRATION_GUIDE.md)
- [RLS Security Guide](docs/guides/FIX_RLS_GUIDE.md)

### 3. Flutter Setup

1. Clone this repository
2. Set up environment variables (see step 1 above)
3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

**Note**: The `.env` file is excluded from version control for security. Make sure to create your own `.env` file based on `.env.example`.

## Project Structure

```
lib/
├── main.dart                     # App entry point
├── constants/                    # App constants
│   └── app_constants.dart
├── models/                       # Data models
│   ├── app_user.dart            # User model (customer/mechanic)
│   ├── mechanic.dart            # Mechanic business profile
│   ├── vehicle.dart             # Vehicle with ITP tracking
│   ├── vehicle_sharing.dart     # Vehicle access sharing
│   ├── maintenance_record.dart  # Service history
│   ├── maintenance_reminder.dart # Maintenance alerts
│   └── models.dart              # Export file
├── providers/                    # State management (Provider pattern)
│   ├── auth_provider.dart       # Authentication state
│   ├── user_provider.dart       # User profile state
│   ├── vehicle_provider.dart    # Vehicle management state
│   └── maintenance_provider.dart # Maintenance state
├── screens/                      # UI screens
│   ├── auth_wrapper.dart        # Auth flow manager
│   ├── login_screen.dart        # Login UI
│   ├── signup_screen.dart       # Multi-step signup
│   ├── profile_setup_screen.dart # Profile completion
│   ├── profile_screen.dart      # Profile management
│   ├── main_screen.dart         # Tab navigation
│   ├── home_screen.dart         # Vehicle list (customers)
│   ├── my_shop_screen.dart      # Shop profile (mechanics)
│   ├── appointments_screen.dart # Appointments (mechanics)
│   ├── add_vehicle_screen.dart  # Add new vehicle
│   ├── edit_vehicle_screen.dart # Edit vehicle
│   ├── vehicle_detail_screen.dart # Vehicle details
│   └── add_maintenance_screen.dart # Add maintenance record
├── services/                     # External services
│   └── supabase_service.dart    # Supabase client & operations
├── utils/                        # Utility functions
│   └── platform_utils.dart      # Platform detection
└── widgets/                      # Reusable UI components
    ├── vehicle_card.dart        # Vehicle list item
    └── next_inspection_card.dart # ITP reminder card

docs/                             # Documentation
├── implementation/               # Feature implementations
├── fixes/                        # Bug fixes
├── troubleshooting/             # Problem solving
├── database/                    # Database & SQL
└── guides/                      # Quick references
```

## Getting Help

### Documentation
- Start with the [Documentation Index](docs/INDEX.md) for a visual guide
- Check [Troubleshooting](docs/troubleshooting/TROUBLESHOOTING.md) for common issues
- Review [Implementation Guides](docs/implementation/) for feature documentation

### Common Issues
- **Email confirmation issues**: See [Email Confirmation Fix](docs/fixes/EMAIL_CONFIRMATION_FIX.md)
- **VIN validation errors**: See [VIN Error Troubleshooting](docs/troubleshooting/VIN_ERROR_TROUBLESHOOTING.md)
- **Database/RLS issues**: See [RLS Security Guide](docs/guides/FIX_RLS_GUIDE.md)
- **Image upload problems**: See [Image Upload Guide](docs/implementation/IMAGE_UPLOAD_SUMMARY.md)

## Next Steps

Planned features for future releases:

1. **Enhanced Maintenance System**
   - Edit and delete maintenance records
   - Advanced filtering and search
   - Cost analytics and reports
   
2. **Notification System**
   - Push notifications for maintenance reminders
   - Email notifications
   - In-app notification center

3. **Mechanic Features**
   - Appointment management and scheduling
   - Customer management
   - Invoice generation
   
4. **Data Export**
   - Export maintenance history to PDF
   - CSV export for data analysis
   - Print-friendly reports

5. **Advanced Features**
   - Photo attachments for maintenance records
   - Service provider directory
   - Multi-vehicle comparison
   - Fuel economy tracking

## MCP (Model Context Protocol) Integration

The project includes MCP configuration for Supabase integration in `.vscode/mcp.json`. This enables enhanced development experience with Supabase services through VS Code.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
