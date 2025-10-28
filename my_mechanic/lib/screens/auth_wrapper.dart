import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
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
}
