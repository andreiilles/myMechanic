import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../utils/platform_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/maintenance_provider.dart';
import '../models/app_user.dart';
import '../widgets/adaptive_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initializeControllers(AppUser user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phoneNumber ?? '';
    _emailController.text = user.email;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.currentUser;
        
        if (user != null) {
          _initializeControllers(user);
        }

        if (PlatformUtils.isIOS) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('Profile'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isEditing)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _saveProfile(userProvider),
                      child: const Text('Save'),
                    )
                  else
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      child: const Text('Edit'),
                    ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showLogoutDialog(context),
                    child: const Icon(CupertinoIcons.square_arrow_right),
                  ),
                ],
              ),
            ),
            child: SafeArea(
              child: _buildBody(user, userProvider),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _saveProfile(userProvider),
                  tooltip: 'Save',
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  tooltip: 'Edit Profile',
                ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context),
                tooltip: 'Logout',
              ),
            ],
          ),
          body: _buildBody(user, userProvider),
        );
      },
    );
  }

  Widget _buildBody(AppUser? user, UserProvider userProvider) {
    if (user == null) {
      return const Center(
        child: Text('No user data available'),
      );
    }

    if (userProvider.isLoading) {
      return Center(
        child: AdaptiveLoadingIndicator(size: 20),
      );
    }

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.3),
                          Theme.of(context).primaryColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      PlatformUtils.isIOS 
                          ? CupertinoIcons.person_fill 
                          : Icons.person,
                      size: 60,
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          PlatformUtils.isIOS 
                              ? CupertinoIcons.camera_fill 
                              : Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // User Type Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: user.userType == UserType.mechanic 
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: user.userType == UserType.mechanic 
                        ? Colors.orange.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.userType == UserType.mechanic 
                          ? (PlatformUtils.isIOS ? CupertinoIcons.wrench_fill : Icons.build)
                          : (PlatformUtils.isIOS ? CupertinoIcons.person_fill : Icons.person),
                      size: 16,
                      color: user.userType == UserType.mechanic 
                          ? Colors.orange[700]
                          : Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.userType.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: user.userType == UserType.mechanic 
                            ? Colors.orange[700]
                            : Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // First Name
            _buildTextField(
              controller: _firstNameController,
              label: 'First Name',
              icon: PlatformUtils.isIOS ? CupertinoIcons.person : Icons.person_outline,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Last Name
            _buildTextField(
              controller: _lastNameController,
              label: 'Last Name',
              icon: PlatformUtils.isIOS ? CupertinoIcons.person : Icons.person_outline,
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Last name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email (Read-only)
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: PlatformUtils.isIOS ? CupertinoIcons.mail : Icons.email_outlined,
              enabled: false,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Phone Number
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: PlatformUtils.isIOS ? CupertinoIcons.phone : Icons.phone_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

            // Cancel Button (only when editing)
            if (_isEditing)
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _initializeControllers(user);
                  });
                },
                child: const Text('Cancel'),
              ),
          ],
        ),
      ),
    );

    // Wrap in Material for iOS to provide Material context for TextFields
    if (PlatformUtils.isIOS) {
      return Material(
        color: CupertinoColors.systemGroupedBackground,
        child: content,
      );
    }

    return content;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: enabled ? null : Colors.grey,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled 
            ? Colors.white.withOpacity(0.7)
            : Colors.grey.withOpacity(0.1),
      ),
    );
  }

  Future<void> _saveProfile(UserProvider userProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = userProvider.currentUser;
    if (user == null) return;

    final updatedUser = user.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty 
          ? null 
          : _phoneController.text.trim(),
    );

    final success = await userProvider.updateUserProfile(updatedUser);

    if (mounted) {
      if (success) {
        setState(() {
          _isEditing = false;
        });
        
        _showMessage('Profile updated successfully', isError: false);
      } else {
        _showMessage(
          userProvider.error ?? 'Failed to update profile',
          isError: true,
        );
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (PlatformUtils.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(isError ? 'Error' : 'Success'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showAdaptiveAlertDialog(
      context: context,
      title: 'Logout',
      content: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true) {
        // Clear all provider data before signing out
        context.read<UserProvider>().clearUserData();
        context.read<VehicleProvider>().clearVehicleData();
        context.read<MaintenanceProvider>().clearMaintenanceData();
        context.read<AuthProvider>().signOut();
      }
    });
  }
}
