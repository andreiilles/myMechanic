import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/app_user.dart';
import '../models/mechanic.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Step 1: Authentication
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Step 2: User Type Selection
  UserType? _selectedUserType;
  
  // Step 3: User Information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Step 4: Mechanic Information (if mechanic)
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  int _currentStep = 0;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _licenseNumberController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

    // Step 1: Create auth account
    final authSuccess = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!authSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to create account'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if email confirmation is required
    // Supabase sends confirmation email automatically
    debugPrint('Auth user ID: ${authProvider.user?.id}');
    debugPrint('Auth user email: ${authProvider.user?.email}');
    debugPrint('Email confirmed: ${authProvider.user?.emailConfirmedAt}');

    // If email is not confirmed, save data to local storage and redirect to login
    if (authProvider.user?.emailConfirmedAt == null) {
      // Save signup data to SharedPreferences for later profile creation
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_signup_email', _emailController.text.trim());
      await prefs.setString('pending_signup_first_name', _firstNameController.text.trim());
      await prefs.setString('pending_signup_last_name', _lastNameController.text.trim());
      await prefs.setString('pending_signup_phone', _phoneController.text.trim());
      await prefs.setString('pending_signup_user_type', _selectedUserType!.toString());
      
      if (_selectedUserType == UserType.mechanic) {
        await prefs.setString('pending_signup_business_name', _businessNameController.text.trim());
        await prefs.setString('pending_signup_business_address', _businessAddressController.text.trim());
        await prefs.setString('pending_signup_license_number', _licenseNumberController.text.trim());
        await prefs.setString('pending_signup_description', _descriptionController.text.trim());
        await prefs.setString('pending_signup_hourly_rate', _hourlyRateController.text.trim());
      }
      
      if (mounted) {
        // Sign out the unconfirmed user
        await authProvider.signOut();
        
        // Pop back to root and let AuthWrapper show LoginScreen
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Show success message after a brief delay to ensure we're back at login
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Account created! Please check your email to confirm your account, then sign in.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
      }
      return;
    }

    // If email is confirmed, continue with profile creation
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 2: Create user profile
    final user = AppUser(
      authId: authProvider.user!.id,
      email: _emailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      userType: _selectedUserType!,
      phoneNumber: _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
    );

    debugPrint('Creating user profile: ${user.toJson(excludeId: true)}');

    final userSuccess = await userProvider.createUserProfile(user);
    if (!userSuccess) {
      if (mounted) {
        String errorMessage = 'Failed to create profile';
        if (userProvider.error != null) {
          if (userProvider.error!.contains('duplicate key')) {
            errorMessage = 'An account with this email already exists';
          } else if (userProvider.error!.contains('violates not-null constraint')) {
            errorMessage = 'Please ensure all required fields are filled';
          } else if (userProvider.error!.contains('violates check constraint')) {
            errorMessage = 'Invalid user type selected';
          } else {
            errorMessage = 'Failed to create profile. Please try again.';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        debugPrint('User profile creation error: ${userProvider.error}');
      }
      return;
    }

    // Step 3: Create mechanic profile if needed
    if (_selectedUserType == UserType.mechanic) {
      final mechanic = Mechanic(
        userId: userProvider.currentUser!.id!,
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim().isEmpty 
            ? null 
            : _businessAddressController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim().isEmpty 
            ? null 
            : _licenseNumberController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        hourlyRate: _hourlyRateController.text.trim().isEmpty 
            ? null 
            : double.tryParse(_hourlyRateController.text.trim()),
      );

      final mechanicSuccess = await userProvider.createMechanicProfile(mechanic);
      if (!mechanicSuccess) {
        if (mounted) {
          String errorMessage = 'Failed to create mechanic profile';
          if (userProvider.error != null) {
            if (userProvider.error!.contains('foreign key')) {
              errorMessage = 'User profile not found. Please try again.';
            } else {
              errorMessage = 'Failed to create mechanic profile. Please try again.';
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          
          debugPrint('Mechanic profile creation error: ${userProvider.error}');
        }
        return;
      }
    }

    // Success - profile created (email was already confirmed)
    // Reload profile and continue to main screen
    await userProvider.loadUserProfile(authProvider.user!.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // The AuthWrapper will automatically navigate to MainScreen
      // since the profile is now loaded
    }
  }

  void _nextStep() {
    if (_currentStep < _getMaxSteps() - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSignUp();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int _getMaxSteps() {
    return _selectedUserType == UserType.mechanic ? 4 : 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: _currentStep > 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _getMaxSteps(),
              backgroundColor: Colors.grey[300],
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildAuthStep(),
                  _buildUserTypeStep(),
                  _buildUserInfoStep(),
                  if (_selectedUserType == UserType.mechanic) _buildMechanicInfoStep(),
                ],
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: Consumer2<AuthProvider, UserProvider>(
                      builder: (context, authProvider, userProvider, child) {
                        final isLoading = authProvider.isLoading || userProvider.isLoading;
                        return ElevatedButton(
                          onPressed: isLoading ? null : _nextStep,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_currentStep == _getMaxSteps() - 1 ? 'Create Account' : 'Next'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email and password to create an account',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email *',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!EmailValidator.validate(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password *',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password *',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I am a...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your account type',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          _buildUserTypeCard(
            userType: UserType.customer,
            title: 'Vehicle Owner',
            description: 'I want to track my vehicle\'s maintenance',
            icon: Icons.directions_car,
          ),
          const SizedBox(height: 16),
          _buildUserTypeCard(
            userType: UserType.mechanic,
            title: 'Mechanic',
            description: 'I provide automotive maintenance services',
            icon: Icons.build,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard({
    required UserType userType,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedUserType == userType;
    
    return Card(
      elevation: isSelected ? 0 : 0,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUserType = userType;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
            gradient: isSelected 
                ? LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.08),
                      Theme.of(context).primaryColor.withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.grey.withOpacity(0.2),
                            Colors.grey.withOpacity(0.1),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us a bit about yourself',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name *',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your mechanic profile',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name *',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your business name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _businessAddressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Business Address',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _licenseNumberController,
            decoration: const InputDecoration(
              labelText: 'License Number',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _hourlyRateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hourly Rate (\$)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
              hintText: 'Tell customers about your services (optional)',
            ),
          ),
        ],
      ),
    );
  }
}
