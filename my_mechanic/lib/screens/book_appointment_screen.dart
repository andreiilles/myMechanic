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
  final _estimatedCostController = TextEditingController();
  
  Vehicle? _selectedVehicle;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  int _durationMinutes = 60;
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

  final List<int> _durations = [30, 60, 90, 120, 180, 240];

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
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
      durationMinutes: _durationMinutes,
      serviceType: _serviceTypeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      estimatedCost: _estimatedCostController.text.trim().isEmpty
          ? null
          : double.tryParse(_estimatedCostController.text.trim()),
    );

    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final success = await appointmentProvider.createAppointment(appointment);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      _showError(appointmentProvider.error ?? 'Failed to book appointment');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
        child: SafeArea(
          child: _buildForm(),
        ),
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
            TextButton(
              onPressed: _bookAppointment,
              child: const Text('Book'),
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
          if (widget.mechanicName != null) ...[
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(widget.mechanicName!),
                subtitle: const Text('Mechanic'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildSectionTitle('Vehicle'),
          const SizedBox(height: 8),
          _buildVehicleSelector(),
          const SizedBox(height: 24),
          _buildSectionTitle('Service Type'),
          const SizedBox(height: 8),
          _buildServiceTypeField(),
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
          _buildSectionTitle('Duration'),
          const SizedBox(height: 8),
          _buildDurationSelector(),
          const SizedBox(height: 24),
          _buildSectionTitle('Description (Optional)'),
          const SizedBox(height: 8),
          _buildDescriptionField(),
          const SizedBox(height: 24),
          _buildSectionTitle('Estimated Cost (Optional)'),
          const SizedBox(height: 8),
          _buildCostField(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
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

        return DropdownButtonFormField<Vehicle>(
          value: _selectedVehicle,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select a vehicle',
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

  Widget _buildServiceTypeField() {
    return DropdownButtonFormField<String>(
      value: _serviceTypeController.text.isEmpty ? null : _serviceTypeController.text,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Select service type',
      ),
      items: _commonServices.map((service) {
        return DropdownMenuItem(
          value: service,
          child: Text(service),
        );
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

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
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

  Widget _buildDurationSelector() {
    return DropdownButtonFormField<int>(
      value: _durationMinutes,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        suffixText: 'minutes',
      ),
      items: _durations.map((duration) {
        return DropdownMenuItem(
          value: duration,
          child: Text('$duration minutes (${(duration / 60).toStringAsFixed(1)} hours)'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _durationMinutes = value);
        }
      },
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

  Widget _buildCostField() {
    return TextFormField(
      controller: _estimatedCostController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        prefixText: '\$ ',
        hintText: '0.00',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}
