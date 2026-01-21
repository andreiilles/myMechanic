import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/platform_utils.dart';
import '../providers/appointment_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/appointment.dart';
import '../models/vehicle.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String mechanicId;
  final String? mechanicName;

  const BookAppointmentScreen({
    super.key,
    required this.mechanicId,
    this.mechanicName,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTypeController = TextEditingController();
  final _descriptionController = TextEditingController();

  Vehicle? _selectedVehicle;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  final List<String> _commonServices = [
    'Oil Change',
    'Tire Rotation',
    'Brake Inspection',
    'General Inspection',
    'Engine Diagnostics',
    'Transmission Service',
    'Air Conditioning Service',
    'Battery Replacement',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.currentUser?.id != null) {
        context.read<VehicleProvider>().loadVehicles(
          userProvider.currentUser!.id!,
        );
      }
    });
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    if (PlatformUtils.isIOS) {
      DateTime tempDate = _selectedDate;
      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey4.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        setState(() => _selectedDate = tempDate);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  minimumDate: DateTime.now(),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    if (PlatformUtils.isIOS) {
      DateTime tempDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey4.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        setState(() {
                          _selectedTime = TimeOfDay(
                            hour: tempDateTime.hour,
                            minute: tempDateTime.minute,
                          );
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: tempDateTime,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempDateTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedVehicle == null) {
      _showError('Please select a vehicle');
      return;
    }

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) {
      _showError('User not found');
      setState(() => _isLoading = false);
      return;
    }

    final appointmentDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final appointment = Appointment(
      customerId: userProvider.currentUser!.id!,
      mechanicId: widget.mechanicId,
      vehicleId: _selectedVehicle!.id!,
      appointmentDate: appointmentDate,
      serviceType: _serviceTypeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    final appointmentProvider = Provider.of<AppointmentProvider>(
      context,
      listen: false,
    );
    final success = await appointmentProvider.createAppointment(appointment);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      if (PlatformUtils.isIOS) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Appointment booked successfully!'),
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
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (mounted) {
      _showError(appointmentProvider.error ?? 'Failed to book appointment');
    }
  }

  void _showError(String message) {
    if (PlatformUtils.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
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
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Book Appointment'),
          trailing: _isLoading
              ? const CupertinoActivityIndicator()
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _bookAppointment,
                  child: const Text('Book'),
                ),
        ),
        child: SafeArea(child: Material(child: _buildForm())),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _bookAppointment, child: const Text('Book')),
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
          if (widget.mechanicName != null) ...[
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(widget.mechanicName!),
                subtitle: const Text('Mechanic'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildSectionTitle('Vehicle'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildVehicleSelector(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Service Type'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildServiceTypeField(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Date & Time'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDateSelector()),
              const SizedBox(width: 12),
              Expanded(child: _buildTimeSelector()),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Description (Optional)'),
          const SizedBox(height: 8),
          _buildDescriptionField(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildVehicleSelector() {
    return Consumer<VehicleProvider>(
      builder: (context, vehicleProvider, child) {
        if (vehicleProvider.vehicles.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No vehicles found. Please add a vehicle first.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        if (PlatformUtils.isIOS) {
          return GestureDetector(
            onTap: () => _showIOSVehiclePicker(vehicleProvider.vehicles),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedVehicle == null
                        ? 'Select a vehicle'
                        : '${_selectedVehicle!.year} ${_selectedVehicle!.make} ${_selectedVehicle!.model}',
                    style: TextStyle(
                      color: _selectedVehicle == null
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.label,
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_down, size: 20),
                ],
              ),
            ),
          );
        }

        return DropdownButtonFormField<Vehicle>(
          value: _selectedVehicle,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select a vehicle',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items: vehicleProvider.vehicles.map((vehicle) {
            return DropdownMenuItem(
              value: vehicle,
              child: Text('${vehicle.year} ${vehicle.make} ${vehicle.model}'),
            );
          }).toList(),
          onChanged: (vehicle) {
            setState(() => _selectedVehicle = vehicle);
          },
          validator: (value) {
            if (value == null) return 'Please select a vehicle';
            return null;
          },
        );
      },
    );
  }

  void _showIOSVehiclePicker(List<Vehicle> vehicles) {
    int selectedIndex = _selectedVehicle != null
        ? vehicles.indexOf(_selectedVehicle!)
        : 0;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey4.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(
                        () => _selectedVehicle = vehicles[selectedIndex],
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                onSelectedItemChanged: (index) {
                  selectedIndex = index;
                },
                children: vehicles.map((vehicle) {
                  return Center(
                    child: Text(
                      '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeField() {
    if (PlatformUtils.isIOS) {
      return GestureDetector(
        onTap: _showIOSServiceTypePicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _serviceTypeController.text.isEmpty
                    ? 'Select service type'
                    : _serviceTypeController.text,
                style: TextStyle(
                  color: _serviceTypeController.text.isEmpty
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.label,
                ),
              ),
              const Icon(CupertinoIcons.chevron_down, size: 20),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _serviceTypeController.text.isEmpty
          ? null
          : _serviceTypeController.text,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Select service type',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: _commonServices.map((service) {
        return DropdownMenuItem(value: service, child: Text(service));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _serviceTypeController.text = value);
        }
      },
      validator: (value) {
        if (_serviceTypeController.text.isEmpty) {
          return 'Please select a service type';
        }
        return null;
      },
    );
  }

  void _showIOSServiceTypePicker() {
    int selectedIndex = _serviceTypeController.text.isEmpty
        ? 0
        : _commonServices.indexOf(_serviceTypeController.text);
    if (selectedIndex == -1) selectedIndex = 0;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey4.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(
                        () => _serviceTypeController.text =
                            _commonServices[selectedIndex],
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: selectedIndex,
                ),
                onSelectedItemChanged: (index) {
                  selectedIndex = index;
                },
                children: _commonServices.map((service) {
                  return Center(child: Text(service));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('MMM dd, yyyy');

    if (PlatformUtils.isIOS) {
      return GestureDetector(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.calendar, size: 20),
              const SizedBox(width: 8),
              Text(dateFormat.format(_selectedDate)),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(dateFormat.format(_selectedDate)),
      ),
    );
  }

  Widget _buildTimeSelector() {
    if (PlatformUtils.isIOS) {
      return GestureDetector(
        onTap: _selectTime,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.time, size: 20),
              const SizedBox(width: 8),
              Text(_selectedTime.format(context)),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _selectTime,
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.access_time),
        ),
        child: Text(_selectedTime.format(context)),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Describe the issue or service needed',
      ),
      maxLines: 4,
    );
  }
}
