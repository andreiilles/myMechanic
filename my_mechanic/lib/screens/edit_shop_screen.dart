import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../models/mechanic.dart';
import '../providers/user_provider.dart';
import '../utils/platform_utils.dart';

class EditShopScreen extends StatefulWidget {
  final Mechanic mechanic;

  const EditShopScreen({super.key, required this.mechanic});

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _businessAddressController;
  late TextEditingController _businessPhoneController;
  late TextEditingController _licenseNumberController;
  late TextEditingController _descriptionController;
  late TextEditingController _hourlyRateController;
  late bool _isAcceptingClients;
  late List<String> _specializations;
  
  bool _isLoading = false;
  bool _isGeocodingAddress = false;

  final List<String> _availableSpecializations = [
    'Engine Repair',
    'Transmission',
    'Brakes',
    'Suspension',
    'Electrical',
    'Air Conditioning',
    'Diagnostics',
    'Oil Change',
    'Tire Service',
    'Body Work',
    'Paint',
    'Detailing',
  ];

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.mechanic.businessName);
    _businessAddressController = TextEditingController(text: widget.mechanic.businessAddress ?? '');
    _businessPhoneController = TextEditingController(text: widget.mechanic.businessPhone ?? '');
    _licenseNumberController = TextEditingController(text: widget.mechanic.licenseNumber ?? '');
    _descriptionController = TextEditingController(text: widget.mechanic.description ?? '');
    _hourlyRateController = TextEditingController(
      text: widget.mechanic.hourlyRate?.toString() ?? '',
    );
    _isAcceptingClients = widget.mechanic.isAcceptingClients;
    _specializations = List.from(widget.mechanic.specializations);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _licenseNumberController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _geocodeAddress() async {
    final address = _businessAddressController.text.trim();
    if (address.isEmpty) return;

    setState(() => _isGeocodingAddress = true);

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty && mounted) {
        _showSnackBar('Location found! Coordinates will be saved.', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Could not find location. Address will be saved without coordinates.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isGeocodingAddress = false);
      }
    }
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Geocode the address if it changed
      double? latitude = widget.mechanic.latitude;
      double? longitude = widget.mechanic.longitude;
      
      if (_businessAddressController.text.trim() != widget.mechanic.businessAddress) {
        try {
          List<Location> locations = await locationFromAddress(_businessAddressController.text.trim());
          if (locations.isNotEmpty) {
            latitude = locations.first.latitude;
            longitude = locations.first.longitude;
          }
        } catch (e) {
          debugPrint('Geocoding failed: $e');
          // Continue without coordinates
        }
      }

      final updatedMechanic = widget.mechanic.copyWith(
        businessName: _businessNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim().isNotEmpty 
            ? _businessAddressController.text.trim() 
            : null,
        businessPhone: _businessPhoneController.text.trim().isNotEmpty 
            ? _businessPhoneController.text.trim() 
            : null,
        licenseNumber: _licenseNumberController.text.trim().isNotEmpty 
            ? _licenseNumberController.text.trim() 
            : null,
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        hourlyRate: _hourlyRateController.text.trim().isNotEmpty 
            ? double.tryParse(_hourlyRateController.text.trim()) 
            : null,
        isAcceptingClients: _isAcceptingClients,
        specializations: _specializations,
        latitude: latitude,
        longitude: longitude,
      );

      final userProvider = context.read<UserProvider>();
      final success = await userProvider.updateMechanicProfile(updatedMechanic);

      if (mounted) {
        if (success) {
          _showSnackBar('Shop information updated successfully!', isError: false);
          Navigator.pop(context);
        } else {
          _showSnackBar('Failed to update shop information', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (PlatformUtils.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(isError ? 'Error' : 'Success'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
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

  void _showSpecializationsDialog() {
    if (PlatformUtils.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => Container(
          height: 400,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Select Specializations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Done'),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _availableSpecializations.length,
                  itemBuilder: (context, index) {
                    final spec = _availableSpecializations[index];
                    final isSelected = _specializations.contains(spec);
                    return CupertinoListTile(
                      title: Text(spec),
                      trailing: isSelected
                          ? const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue)
                          : null,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _specializations.remove(spec);
                          } else {
                            _specializations.add(spec);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Select Specializations'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableSpecializations.length,
                    itemBuilder: (context, index) {
                      final spec = _availableSpecializations[index];
                      final isSelected = _specializations.contains(spec);
                      return CheckboxListTile(
                        title: Text(spec),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              _specializations.add(spec);
                            } else {
                              _specializations.remove(spec);
                            }
                          });
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Edit Shop'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          trailing: _isLoading
              ? const CupertinoActivityIndicator()
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Save'),
                  onPressed: _saveShop,
                ),
        ),
        child: SafeArea(
          child: _buildForm(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Shop'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveShop,
            ),
        ],
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Name
          _buildSectionTitle('Basic Information'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _businessNameController,
            label: 'Business Name',
            icon: PlatformUtils.isIOS ? CupertinoIcons.building_2_fill : Icons.business,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your business name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Business Address
          _buildTextField(
            controller: _businessAddressController,
            label: 'Business Address',
            icon: PlatformUtils.isIOS ? CupertinoIcons.location_solid : Icons.location_on,
            maxLines: 2,
            keyboardType: TextInputType.streetAddress,
            suffix: _isGeocodingAddress
                ? (PlatformUtils.isIOS 
                    ? const CupertinoActivityIndicator() 
                    : const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ))
                : IconButton(
                    icon: Icon(
                      PlatformUtils.isIOS ? CupertinoIcons.search : Icons.search,
                      size: 20,
                    ),
                    onPressed: _geocodeAddress,
                    tooltip: 'Find location',
                  ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'We will automatically find the coordinates for map display',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Business Phone
          _buildTextField(
            controller: _businessPhoneController,
            label: 'Business Phone',
            icon: PlatformUtils.isIOS ? CupertinoIcons.phone_fill : Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // License Number
          _buildTextField(
            controller: _licenseNumberController,
            label: 'License Number',
            icon: PlatformUtils.isIOS ? CupertinoIcons.doc_text_fill : Icons.badge,
          ),
          const SizedBox(height: 24),

          // Pricing & Services
          _buildSectionTitle('Pricing & Services'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _hourlyRateController,
            label: 'Hourly Rate (RON)',
            icon: PlatformUtils.isIOS ? CupertinoIcons.money_dollar_circle_fill : Icons.attach_money,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final rate = double.tryParse(value.trim());
                if (rate == null || rate < 0) {
                  return 'Please enter a valid hourly rate';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Specializations
          Card(
            child: InkWell(
              onTap: _showSpecializationsDialog,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PlatformUtils.isIOS ? CupertinoIcons.wrench_fill : Icons.build,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Specializations',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Icon(
                          PlatformUtils.isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    if (_specializations.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _specializations.map((spec) {
                          return Chip(
                            label: Text(spec),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _specializations.remove(spec);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add specializations',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Description
          _buildSectionTitle('About Your Shop'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            icon: PlatformUtils.isIOS ? CupertinoIcons.text_alignleft : Icons.description,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tell customers about your shop, experience, and what makes you unique',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Accepting Clients Toggle
          _buildSectionTitle('Availability'),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Accepting New Clients'),
              subtitle: Text(
                _isAcceptingClients
                    ? 'Your shop is visible to customers'
                    : 'Your shop is hidden from new bookings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              secondary: Icon(
                _isAcceptingClients
                    ? (PlatformUtils.isIOS ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle)
                    : (PlatformUtils.isIOS ? CupertinoIcons.pause_circle_fill : Icons.pause_circle),
                color: _isAcceptingClients ? Colors.green : Colors.orange,
              ),
              value: _isAcceptingClients,
              onChanged: (value) {
                setState(() {
                  _isAcceptingClients = value;
                });
              },
            ),
          ),
          const SizedBox(height: 24),

          // Save Button (for Material design bottom)
          if (!PlatformUtils.isIOS)
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveShop,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? suffix,
  }) {
    if (PlatformUtils.isIOS) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: CupertinoColors.systemGrey),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: controller,
                      placeholder: label,
                      decoration: const BoxDecoration(),
                      keyboardType: keyboardType,
                      maxLines: maxLines,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  if (suffix != null) suffix,
                ],
              ),
            ],
          ),
        ),
      );
    }

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon: suffix,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }
}
