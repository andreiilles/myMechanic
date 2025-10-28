class AppConstants {
  static const String appName = 'My Mechanic';
  static const String appDescription = 'Track your car maintenance';
  
  // Maintenance intervals (in kilometers)
  static const int oilChangeInterval = 10000;
  static const int inspectionInterval = 20000;
  static const int tireRotationInterval = 15000;
  
  // Maintenance types with default intervals
  static const Map<String, int> maintenanceIntervals = {
    'oilChange': oilChangeInterval,
    'inspection': inspectionInterval,
    'tireRotation': tireRotationInterval,
    'brakeService': 40000,
    'engineService': 100000,
    'transmission': 100000,
    'coolantFlush': 50000,
    'sparkPlugs': 50000,
    'airFilter': 20000,
    'fuelFilter': 40000,
    'batteryReplacement': 150000, // or 3 years
  };
  
  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Validation constants
  static const int minVinLength = 17;
  static const int maxVinLength = 17;
  static const int minYear = 1900;
  static const int maxMileage = 9999999;
}
