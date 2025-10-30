import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/vehicle.dart';
import '../utils/platform_utils.dart';
import '../services/supabase_service.dart';

class ShareVehicleDialog extends StatefulWidget {
  final Vehicle vehicle;

  const ShareVehicleDialog({
    super.key,
    required this.vehicle,
  });

  @override
  State<ShareVehicleDialog> createState() => _ShareVehicleDialogState();
}

class _ShareVehicleDialogState extends State<ShareVehicleDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String _selectedRelationship = 'family_member';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _shareVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      
      // Find user by email
      final response = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _errorMessage = 'No user found with email: $email';
          _isLoading = false;
        });
        return;
      }

      final userId = response['id'] as String;
      
      // Check if user already has access
      final existingLink = await SupabaseService.client
          .from('user_vehicles')
          .select()
          .eq('user_id', userId)
          .eq('vehicle_id', widget.vehicle.id!)
          .maybeSingle();

      if (existingLink != null) {
        setState(() {
          _errorMessage = 'This user already has access to this vehicle';
          _isLoading = false;
        });
        return;
      }

      // Add user to vehicle
      await SupabaseService.client
          .from('user_vehicles')
          .insert({
            'user_id': userId,
            'vehicle_id': widget.vehicle.id!,
            'relationship': _selectedRelationship,
          });

      setState(() {
        _successMessage = 'Vehicle shared successfully with $email';
        _isLoading = false;
        _emailController.clear();
      });

      // Close dialog after a delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to share vehicle: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoAlertDialog(
        title: const Text('Share Vehicle'),
        content: _buildDialogContent(),
        actions: [
          CupertinoDialogAction(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: _isLoading ? null : _shareVehicle,
            isDefaultAction: true,
            child: _isLoading
                ? const CupertinoActivityIndicator()
                : const Text('Share'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Share Vehicle'),
      content: _buildDialogContent(),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _shareVehicle,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Share'),
        ),
      ],
    );
  }

  Widget _buildDialogContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Share ${widget.vehicle.year} ${widget.vehicle.make} ${widget.vehicle.model}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (PlatformUtils.isIOS)
                  CupertinoTextField(
                    controller: _emailController,
                    placeholder: 'User email address',
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                  )
                else
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter user email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an email address';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Relationship',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                if (PlatformUtils.isIOS)
                  CupertinoSegmentedControl<String>(
                    groupValue: _selectedRelationship,
                    onValueChanged: (value) {
                      setState(() => _selectedRelationship = value);
                    },
                    children: const {
                      'family_member': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text('Family', style: TextStyle(fontSize: 12)),
                      ),
                      'shared': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text('Friend', style: TextStyle(fontSize: 12)),
                      ),
                    },
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedRelationship,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'family_member',
                        child: Text('Family Member'),
                      ),
                      DropdownMenuItem(
                        value: 'shared',
                        child: Text('Friend/Shared'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRelationship = value);
                      }
                    },
                  ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'The user will be able to view and manage this vehicle and its maintenance records.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
