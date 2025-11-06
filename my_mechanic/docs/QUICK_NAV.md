# Quick Navigation - myMechanic Documentation

## 🚀 Start Here

- **New to the project?** → Start with the main [README](../README.md)
- **Setting up the database?** → Check [Database Setup](database/MIGRATION_GUIDE.md)
- **Need to fix something?** → Browse [Fixes](fixes/)
- **Implementing a feature?** → See [Implementation Guides](implementation/)

## 📑 Most Used Documents

### For Developers

1. **[Vehicle Management Implementation](implementation/VEHICLE_DETAIL_IMPLEMENTATION.md)**
2. **[Database Migration Guide](database/MIGRATION_GUIDE.md)**
3. **[Platform Adaptive UI](implementation/PLATFORM_ADAPTIVE_UI.md)**
4. **[Troubleshooting Guide](troubleshooting/TROUBLESHOOTING.md)**

### For Database Management

1. **[SQL Scripts Index](database/sql/README.md)**
2. **[RLS Guide](fixes/FIX_RLS_GUIDE.md)**
3. **[Migrations Summary](database/MIGRATIONS_SUMMARY.md)**

### For Bug Fixes

1. **[VIN Error Troubleshooting](troubleshooting/VIN_ERROR_TROUBLESHOOTING.md)**
2. **[Emergency Fix Instructions](fixes/EMERGENCY_FIX_INSTRUCTIONS.md)**
3. **[Common Issues](troubleshooting/TROUBLESHOOTING.md)**

## 🔍 Search by Topic

### Authentication & Users
- [Email Confirmation Fix](fixes/EMAIL_CONFIRMATION_FIX.md)
- [Sign In Button Fix](fixes/SIGNIN_BUTTON_FIX.md)
- [Role Based Navigation](implementation/ROLE_BASED_NAVIGATION.md)

### Vehicles
- [Vehicle Detail Implementation](implementation/VEHICLE_DETAIL_IMPLEMENTATION.md)
- [Vehicle ID Fix](fixes/VEHICLE_ID_FIX.md)
- [Vehicle Sharing](implementation/VEHICLE_SHARING_IMPLEMENTATION.md)
- [Vehicle Sharing Quick Summary](guides/VEHICLE_SHARING_QUICK_SUMMARY.md)

### VIN (Vehicle Identification Number)
- [VIN Uniqueness Fix](fixes/VIN_UNIQUENESS_FIX.md)
- [VIN Error Troubleshooting](troubleshooting/VIN_ERROR_TROUBLESHOOTING.md)
- [Duplicate VIN Error Handling](troubleshooting/DUPLICATE_VIN_ERROR_HANDLING.md)
- [Final VIN Fix Summary](fixes/FINAL_VIN_FIX_SUMMARY.md)

### Maintenance
- [Maintenance Implementation](implementation/VEHICLE_MAINTENANCE_IMPLEMENTATION.md)
- [Add Maintenance Button Fix](fixes/FIX_ADD_MAINTENANCE_BUTTON.md)

### UI/UX
- [Platform Adaptive UI](implementation/PLATFORM_ADAPTIVE_UI.md)
- [Adaptive UI Summary](implementation/ADAPTIVE_UI_SUMMARY.md)
- [Scaffold Fix](fixes/SCAFFOLD_FIX.md)

### Images
- [Image Upload Summary](implementation/IMAGE_UPLOAD_SUMMARY.md)
- [Vehicle Image Setup](implementation/VEHICLE_IMAGE_SETUP.md)

### Database
- [Migration Guide](database/MIGRATION_GUIDE.md)
- [RLS Guide](fixes/FIX_RLS_GUIDE.md)
- [User Vehicles Table Fix](fixes/FIX_USER_VEHICLES_TABLE.md)
- [SQL Scripts](database/sql/README.md)

## 📊 Documentation Structure

```
docs/
├── README.md                    # Main documentation index
├── QUICK_NAV.md                # This file
├── implementation/             # Feature implementations
│   ├── VEHICLE_*.md
│   ├── MAINTENANCE_*.md
│   ├── IMAGE_*.md
│   └── UI_*.md
├── fixes/                      # Bug fixes and patches
│   ├── FIX_*.md
│   └── *_FIX.md
├── troubleshooting/           # Problem-solving guides
│   ├── TROUBLESHOOTING.md
│   └── *_ERROR_*.md
├── guides/                    # Quick reference guides
│   └── *_SUMMARY.md
└── database/                  # Database documentation
    ├── MIGRATION_*.md
    └── sql/                   # SQL scripts
        └── *.sql
```

## 💡 Tips

- Use your IDE's search (Ctrl/Cmd + Shift + F) to find content across all docs
- Check the [Troubleshooting](troubleshooting/) folder first when encountering errors
- Always review [Database](database/) docs before making schema changes
- Keep this navigation file updated when adding new documentation

## 🆘 Need Help?

If you can't find what you're looking for:
1. Check the [Troubleshooting Guide](troubleshooting/TROUBLESHOOTING.md)
2. Search for keywords in the [Main README](README.md)
3. Review recent [Fixes](fixes/) for similar issues
