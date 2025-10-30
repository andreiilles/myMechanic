import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import '../providers/maintenance_provider.dart';
import '../utils/platform_utils.dart';

class AddMaintenanceScreen extends StatefulWidget {
  final Vehicle vehicle;

  const AddMaintenanceScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _mileageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serviceProviderController = TextEditingController();
  final _notesController = TextEditingController();

  MaintenanceType _selectedType = MaintenanceType.oilChange;
  DateTime _serviceDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    debugPrint('AddMaintenanceScreen initialized for vehicle: ${widget.vehicle.id}');
    // Pre-fill mileage with current vehicle mileage
    _mileageController.text = widget.vehicle.currentMileage.toString();
  }

  @override
  void dispose() {
    _costController.dispose();
    _mileageController.dispose();
    _descriptionController.dispose();
    _serviceProviderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always use Material Scaffold for form consistency
    // Even on iOS, we need Material widgets for TextFormField
    return Scaffold(
      appBar: PlatformUtils.isIOS
          ? AppBar(
              title: const Text('Add Maintenance'),
              leading: TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              actions: [
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CupertinoActivityIndicator(),
                  )
                else
                  TextButton(
                    onPressed: _saveMaintenance,
                    child: const Text('Save'),
                  ),
              ],
            )
          : AppBar(
              title: const Text('Add Maintenance'),
              actions: [
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _saveMaintenance,
                  ),
              ],
            ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.vehicle.year} ${widget.vehicle.make} ${widget.vehicle.model}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.vehicle.licensePlate != null)
                      Text(
                        widget.vehicle.licensePlate!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Service Type
            Text(
              'Service Type',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildServiceTypeDropdown(),
            const SizedBox(height: 24),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 16),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Cost
            TextFormField(
              controller: _costController,
              decoration: InputDecoration(
                labelText: 'Cost',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 16),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the cost';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mileage
            TextFormField(
              controller: _mileageController,
              decoration: InputDecoration(
                labelText: 'Mileage',
                suffixText: 'km',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 16),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the mileage';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Service Date
            Text(
              'Service Date',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDatePicker(),
            const SizedBox(height: 16),

            // Service Provider
            TextFormField(
              controller: _serviceProviderController,
              decoration: InputDecoration(
                labelText: 'Service Provider (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 16),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Save Button (Material only, iOS has it in nav bar)
            if (!PlatformUtils.isIOS)
              ElevatedButton(
                onPressed: _isSaving ? null : _saveMaintenance,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Save Maintenance Record'),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeDropdown() {
    if (PlatformUtils.isIOS) {
      return GestureDetector(
        onTap: _showIOSPicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
            color: CupertinoColors.systemBackground.resolveFrom(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedType.displayName,
                style: const TextStyle(fontSize: 16),
              ),
              const Icon(CupertinoIcons.chevron_down, size: 18),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<MaintenanceType>(
      value: _selectedType,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: MaintenanceType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedType = value;
          });
        }
      },
    );
  }

  void _showIOSPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedType = MaintenanceType.values[index];
                    });
                  },
                  scrollController: FixedExtentScrollController(
                    initialItem: MaintenanceType.values.indexOf(_selectedType),
                  ),
                  children: MaintenanceType.values.map((type) {
                    return Center(child: Text(type.displayName));
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatePicker() {
    final formattedDate = '${_serviceDate.day.toString().padLeft(2, '0')}/${_serviceDate.month.toString().padLeft(2, '0')}/${_serviceDate.year}';

    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: PlatformUtils.isIOS 
                ? CupertinoColors.systemGrey4 
                : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(8),
          color: PlatformUtils.isIOS 
              ? CupertinoColors.systemBackground.resolveFrom(context)
              : Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 16),
            ),
            Icon(
              PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    if (PlatformUtils.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _serviceDate,
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (DateTime newDate) {
                      setState(() {
                        _serviceDate = newDate;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _serviceDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null && picked != _serviceDate) {
        setState(() {
          _serviceDate = picked;
        });
      }
    }
  }

  Future<void> _saveMaintenance() async {
    if (_isSaving) return; // Prevent double-tap
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final maintenanceProvider = context.read<MaintenanceProvider>();

      final record = MaintenanceRecord(
        vehicleId: widget.vehicle.id!,
        type: _selectedType,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        cost: double.parse(_costController.text),
        mileageAtService: int.parse(_mileageController.text),
        serviceDate: _serviceDate,
        serviceProvider: _serviceProviderController.text.trim().isEmpty 
            ? null 
            : _serviceProviderController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );

      final success = await maintenanceProvider.addRecord(record);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maintenance record added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(maintenanceProvider.error ?? 'Failed to add maintenance record'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
