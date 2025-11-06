import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/app_user.dart';
import '../models/mechanic.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'profile_setup_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoadingProfile = false;
  bool _hasAttemptedLoad = false;

  @override
  void initState() {
    super.initState();
    // Load profile after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadProfile();
    });
  }

  void _checkAndLoadProfile() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated && 
        userProvider.currentUser == null && 
        !_hasAttemptedLoad && 
        !_isLoadingProfile) {
      _loadUserProfile(authProvider, userProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        // Not authenticated - show login
        if (!authProvider.isAuthenticated) {
          // Reset flags when user logs out
          if (_hasAttemptedLoad || _isLoadingProfile) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _hasAttemptedLoad = false;
                _isLoadingProfile = false;
              });
            });
          }
          return const LoginScreen();
        }

        // Authenticated but haven't loaded profile yet
        if (userProvider.currentUser == null && !_hasAttemptedLoad && !_isLoadingProfile) {
          // Schedule profile loading after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndLoadProfile();
          });
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          );
        }

        // Loading profile
        if (_isLoadingProfile) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          );
        }

        // Profile loaded successfully
        if (userProvider.currentUser != null) {
          return const MainScreen();
        }

        // Profile doesn't exist - show setup screen
        return const ProfileSetupScreen();
      },
    );
  }

  void _loadUserProfile(AuthProvider authProvider, UserProvider userProvider) async {
    if (_isLoadingProfile || _hasAttemptedLoad) return;

    setState(() {
      _isLoadingProfile = true;
    });

    try {
      await userProvider.loadUserProfile(authProvider.user!.id);
      
      // If profile doesn't exist, check for pending signup data
      if (userProvider.currentUser == null) {
        await _checkAndCreatePendingProfile(authProvider, userProvider);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _hasAttemptedLoad = true;
        });
      }
    }
  }

  Future<void> _checkAndCreatePendingProfile(AuthProvider authProvider, UserProvider userProvider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingEmail = prefs.getString('pending_signup_email');
      
      // Check if there's pending signup data for this email
      if (pendingEmail != null && pendingEmail == authProvider.user!.email) {
        debugPrint('Found pending signup data, creating profile...');
        
        final firstName = prefs.getString('pending_signup_first_name') ?? '';
        final lastName = prefs.getString('pending_signup_last_name') ?? '';
        final phone = prefs.getString('pending_signup_phone') ?? '';
        final userTypeStr = prefs.getString('pending_signup_user_type') ?? '';
        
        // Parse user type
        UserType? userType;
        if (userTypeStr.contains('customer')) {
          userType = UserType.customer;
        } else if (userTypeStr.contains('mechanic')) {
          userType = UserType.mechanic;
        }
        
        if (userType != null && firstName.isNotEmpty && lastName.isNotEmpty) {
          // Create user profile
          final user = AppUser(
            authId: authProvider.user!.id,
            email: authProvider.user!.email!,
            firstName: firstName,
            lastName: lastName,
            userType: userType,
            phoneNumber: phone.isEmpty ? null : phone,
          );
          
          final userSuccess = await userProvider.createUserProfile(user);
          
          if (userSuccess && userType == UserType.mechanic) {
            // Create mechanic profile
            final businessName = prefs.getString('pending_signup_business_name') ?? '';
            final businessAddress = prefs.getString('pending_signup_business_address') ?? '';
            final licenseNumber = prefs.getString('pending_signup_license_number') ?? '';
            final description = prefs.getString('pending_signup_description') ?? '';
            final hourlyRateStr = prefs.getString('pending_signup_hourly_rate') ?? '';
            
            if (businessName.isNotEmpty) {
              final mechanic = Mechanic(
                userId: userProvider.currentUser!.id!,
                businessName: businessName,
                businessAddress: businessAddress.isEmpty ? null : businessAddress,
                licenseNumber: licenseNumber.isEmpty ? null : licenseNumber,
                description: description.isEmpty ? null : description,
                hourlyRate: hourlyRateStr.isEmpty ? null : double.tryParse(hourlyRateStr),
              );
              
              await userProvider.createMechanicProfile(mechanic);
            }
          }
          
          // Clear pending signup data
          await prefs.remove('pending_signup_email');
          await prefs.remove('pending_signup_first_name');
          await prefs.remove('pending_signup_last_name');
          await prefs.remove('pending_signup_phone');
          await prefs.remove('pending_signup_user_type');
          await prefs.remove('pending_signup_business_name');
          await prefs.remove('pending_signup_business_address');
          await prefs.remove('pending_signup_license_number');
          await prefs.remove('pending_signup_description');
          await prefs.remove('pending_signup_hourly_rate');
          
          debugPrint('Profile created from pending signup data');
        }
      }
    } catch (e) {
      debugPrint('Error creating profile from pending data: $e');
    }
  }
}
