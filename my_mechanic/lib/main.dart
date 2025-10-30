import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/maintenance_provider.dart';
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
      ],
      child: MaterialApp(
        title: 'My Mechanic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1976D2),
            brightness: Brightness.light,
          ),
          textTheme: Platform.isIOS 
              ? const TextTheme(
                  // Use SF Pro for iOS (system default)
                  displayLarge: TextStyle(fontFamily: '.SF Pro Display'),
                  displayMedium: TextStyle(fontFamily: '.SF Pro Display'),
                  displaySmall: TextStyle(fontFamily: '.SF Pro Display'),
                  headlineLarge: TextStyle(fontFamily: '.SF Pro Display'),
                  headlineMedium: TextStyle(fontFamily: '.SF Pro Display'),
                  headlineSmall: TextStyle(fontFamily: '.SF Pro Display'),
                  titleLarge: TextStyle(fontFamily: '.SF Pro Display'),
                  titleMedium: TextStyle(fontFamily: '.SF Pro Display'),
                  titleSmall: TextStyle(fontFamily: '.SF Pro Display'),
                  bodyLarge: TextStyle(fontFamily: '.SF Pro Text'),
                  bodyMedium: TextStyle(fontFamily: '.SF Pro Text'),
                  bodySmall: TextStyle(fontFamily: '.SF Pro Text'),
                  labelLarge: TextStyle(fontFamily: '.SF Pro Text'),
                  labelMedium: TextStyle(fontFamily: '.SF Pro Text'),
                  labelSmall: TextStyle(fontFamily: '.SF Pro Text'),
                )
              : GoogleFonts.interTextTheme(),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
        },
      ),
    );
  }
}


