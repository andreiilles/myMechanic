import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../utils/platform_utils.dart';
import '../services/supabase_service.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final Appointment appointment;
  final bool isMechanic;

  const AppointmentDetailScreen({
    super.key,
    required this.appointment,
    required this.isMechanic,
  });

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final _responseController = TextEditingController();
  DateTime? _proposedDate;
  TimeOfDay? _proposedTime;
  bool _isLoading = false;
  List<Map<String, dynamic>> _maintenanceRecords = [];
  bool _loadingRecords = false;
  Map<String, dynamic>? _mechanicShop;

  @override
  void initState() {
    super.initState();
    
    // Debug logging
    debugPrint('=== Appointment Detail Debug ===');
    debugPrint('isMechanic: ${widget.isMechanic}');
    debugPrint('customer != null: ${widget.appointment.customer != null}');
    debugPrint('customer data: ${widget.appointment.customer}');
    debugPrint('vehicle != null: ${widget.appointment.vehicle != null}');
    debugPrint('vehicle data: ${widget.appointment.vehicle}');
    debugPrint('vehicleId: ${widget.appointment.vehicleId}');
    debugPrint('Check condition: isMechanic=${widget.isMechanic}, vehicle null check=${widget.appointment.vehicle != null}');
    debugPrint('Should show vehicle? ${widget.isMechanic && widget.appointment.vehicle != null}');
    
    if (widget.isMechanic) {
      _loadMaintenanceRecords();
    } else {
      _loadMechanicShop();
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadMechanicShop() async {
    try {
      final response = await SupabaseService.client
          .from('mechanic_profiles')
          .select()
          .eq('user_id', widget.appointment.mechanicId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _mechanicShop = response;
        });
      }
    } catch (e) {
      debugPrint('Error loading mechanic shop: $e');
    }
  }

  Future<void> _loadMaintenanceRecords() async {
    if (!mounted) return;
    setState(() => _loadingRecords = true);

    try {
      final response = await SupabaseService.client
          .from('maintenance_records')
          .select()
          .eq('vehicle_id', widget.appointment.vehicleId)
          .order('service_date', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _maintenanceRecords = List<Map<String, dynamic>>.from(response);
          _loadingRecords = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading maintenance records: $e');
      if (mounted) {
        setState(() => _loadingRecords = false);
      }
    }
  }

  Future<void> _cancelAppointment() async {
    final TextEditingController reasonController = TextEditingController();
    
    final shouldCancel = await (PlatformUtils.isIOS
        ? showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Cancel Appointment'),
              content: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text('Are you sure you want to cancel this appointment?'),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: reasonController,
                    placeholder: 'Reason for cancellation (optional)',
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('No'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Yes, Cancel'),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          )
        : showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancel Appointment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Are you sure you want to cancel this appointment?'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Reason for cancellation (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
          ));

    if (shouldCancel == true && mounted) {
      setState(() => _isLoading = true);

      final success = await context.read<AppointmentProvider>().cancelAppointment(
        widget.appointment.id!,
        reason: reasonController.text.isNotEmpty ? reasonController.text : null,
        isMechanic: widget.isMechanic,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          _showSuccessDialog('Appointment cancelled successfully');
        } else {
          _showErrorDialog('Failed to cancel appointment');
        }
      }
    }
    reasonController.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${date.day} ${months[date.month - 1]} ${date.year} at $time';
  }

  Future<void> _openMaps() async {
    final shop = _mechanicShop;
    if (shop == null || shop['latitude'] == null || shop['longitude'] == null) {
      _showErrorDialog('Location not available');
      return;
    }

    final lat = shop['latitude'];
    final lng = shop['longitude'];
    final address = Uri.encodeComponent(shop['business_address'] ?? '');

    // Try Google Maps first
    final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback to Apple Maps on iOS
    if (PlatformUtils.isIOS) {
      final appleUrl = Uri.parse('https://maps.apple.com/?q=$address&ll=$lat,$lng');
      if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
        return;
      }
    }

    _showErrorDialog('Could not open maps');
  }

  Future<void> _selectProposedDate() async {
    if (PlatformUtils.isIOS) {
      await showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: _proposedDate ?? DateTime.now().add(const Duration(days: 1)),
                  minimumDate: DateTime.now(),
                  onDateTimeChanged: (date) {
                    setState(() {
                      _proposedDate = date;
                      _proposedTime = TimeOfDay.fromDateTime(date);
                    });
                  },
                ),
              ),
              CupertinoButton(
                child: const Text('Done'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _proposedDate ?? DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)),
      );
      if (picked != null) {
        final time = await showTimePicker(
          context: context,
          initialTime: _proposedTime ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (time != null) {
          setState(() {
            _proposedDate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              time.hour,
              time.minute,
            );
            _proposedTime = time;
          });
        }
      }
    }
  }

  Future<void> _acceptAppointment() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final success = await context.read<AppointmentProvider>().acceptAppointment(
      widget.appointment.id!,
      response: _responseController.text.trim().isNotEmpty
          ? _responseController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        _showSuccessDialog('Appointment accepted successfully!');
      } else {
        _showErrorDialog('Failed to accept appointment');
      }
    }
  }

  Future<void> _declineAppointment() async {
    final reason = await _showDeclineReasonDialog();
    if (reason == null || !mounted) return;

    setState(() => _isLoading = true);

    final success = await context.read<AppointmentProvider>().declineAppointment(
      widget.appointment.id!,
      reason: reason,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        _showSuccessDialog('Appointment declined');
      } else {
        _showErrorDialog('Failed to decline appointment');
      }
    }
  }

  Future<void> _proposeAlternativeDate() async {
    if (_proposedDate == null) {
      _showErrorDialog('Please select a proposed date and time');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final success = await context.read<AppointmentProvider>().proposeAlternativeDate(
      widget.appointment.id!,
      _proposedDate!,
      message: _responseController.text.trim().isNotEmpty
          ? _responseController.text.trim()
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        _showSuccessDialog('Alternative date proposed successfully!');
      } else {
        _showErrorDialog('Failed to propose alternative date');
      }
    }
  }

  Future<String?> _showDeclineReasonDialog() async {
    final controller = TextEditingController();
    
    if (PlatformUtils.isIOS) {
      return await showCupertinoDialog<String>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Decline Reason'),
          content: Column(
            children: [
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: controller,
                placeholder: 'Enter reason (optional)',
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Decline'),
            ),
          ],
        ),
      );
    }

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showSuccessDialog(String message) {
    if (PlatformUtils.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context); // Close dialog only
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog only
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Appointment Details'),
        ),
        child: SafeArea(
          child: _buildContent(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge (hide for accepted appointments)
          if (widget.appointment.status != AppointmentStatus.accepted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.appointment.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.appointment.status.displayName,
                style: TextStyle(
                  color: _getStatusColor(widget.appointment.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Service Type
          Text(
            widget.appointment.serviceType,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Date & Time Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Requested Date & Time',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDate(widget.appointment.appointmentDate),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.appointment.appointmentDate.hour.toString().padLeft(2, '0')}:${widget.appointment.appointmentDate.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Customer Info (for mechanic)
          if (widget.isMechanic && widget.appointment.customer != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PlatformUtils.isIOS ? CupertinoIcons.person_fill : Icons.person,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Customer Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Name', '${widget.appointment.customer!['first_name']} ${widget.appointment.customer!['last_name']}'),
                    _buildInfoRow('Phone', widget.appointment.customer!['phone_number'] ?? 'Not provided'),
                    _buildInfoRow('Email', widget.appointment.customer!['email']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Vehicle Info (for mechanic)
          if (widget.isMechanic && widget.appointment.vehicle != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PlatformUtils.isIOS ? CupertinoIcons.car_fill : Icons.directions_car,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vehicle Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Vehicle', '${widget.appointment.vehicle!['make']} ${widget.appointment.vehicle!['model']}'),
                    _buildInfoRow('Year', widget.appointment.vehicle!['year'].toString()),
                    _buildInfoRow('VIN', widget.appointment.vehicle!['vin']),
                    _buildInfoRow('Mileage', '${widget.appointment.vehicle!['current_mileage']} km'),
                    _buildInfoRow('License Plate', widget.appointment.vehicle!['license_plate'] ?? 'N/A'),
                    if (widget.appointment.vehicle!['color'] != null)
                      _buildInfoRow('Color', widget.appointment.vehicle!['color']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Vehicle Info (for customer - simple version)
          if (!widget.isMechanic && widget.appointment.vehicle != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PlatformUtils.isIOS ? CupertinoIcons.car_fill : Icons.directions_car,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vehicle Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Vehicle', '${widget.appointment.vehicle!['make']} ${widget.appointment.vehicle!['model']}'),
                    _buildInfoRow('Year', widget.appointment.vehicle!['year'].toString()),
                    _buildInfoRow('License Plate', widget.appointment.vehicle!['license_plate'] ?? 'N/A'),
                    if (widget.appointment.vehicle!['color'] != null)
                      _buildInfoRow('Color', widget.appointment.vehicle!['color']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Shop Info (for customer)
          if (!widget.isMechanic && _mechanicShop != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PlatformUtils.isIOS ? CupertinoIcons.building_2_fill : Icons.business,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Shop Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Shop Name', _mechanicShop!['business_name']),
                    if (_mechanicShop!['business_phone'] != null)
                      _buildInfoRow('Phone', _mechanicShop!['business_phone']),
                    if (_mechanicShop!['business_address'] != null)
                      _buildInfoRow('Address', _mechanicShop!['business_address']),
                    if (_mechanicShop!['hourly_rate'] != null)
                      _buildInfoRow('Hourly Rate', '\$${_mechanicShop!['hourly_rate']}/hr'),
                    const SizedBox(height: 12),
                    if (_mechanicShop!['latitude'] != null && 
                        _mechanicShop!['longitude'] != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openMaps,
                          icon: const Icon(Icons.directions),
                          label: const Text('Get Directions'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Maintenance History (for mechanic)
          if (widget.isMechanic && widget.appointment.vehicle != null) ...[
            Card(
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
                        Expanded(
                          child: Text(
                            'Maintenance History',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_loadingRecords)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_maintenanceRecords.isEmpty && !_loadingRecords)
                      Text(
                        'No maintenance history available',
                        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    if (_maintenanceRecords.isNotEmpty)
                      ..._maintenanceRecords.take(5).map((record) {
                        final date = DateTime.parse(record['service_date']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record['type'] ?? 'Service',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${date.day}/${date.month}/${date.year} • ${record['mileage_at_service']} km',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    if (record['description'] != null)
                                      Text(
                                        record['description'],
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Description (full width, hide if empty)
          if (widget.appointment.description != null && widget.appointment.description!.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          widget.appointment.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Mechanic Actions (only for pending appointments)
          if (widget.isMechanic && widget.appointment.status == AppointmentStatus.pending) ...[
            Text(
              'Response',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _responseController,
                  decoration: const InputDecoration(
                    hintText: 'Add a message (optional)',
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Propose alternative date section
            Card(
              child: InkWell(
                onTap: _selectProposedDate,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.event,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Propose Alternative Date',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            if (_proposedDate != null)
                              Text(
                                _formatDateTime(_proposedDate!),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        PlatformUtils.isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _declineAppointment,
                    icon: const Icon(Icons.close),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _acceptAppointment,
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_proposedDate != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _proposeAlternativeDate,
                  icon: const Icon(Icons.event),
                  label: const Text('Propose Alternative Date'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],

          // Mechanic Response (if exists)
          if (widget.appointment.mechanicResponse != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Mechanic Response',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(widget.appointment.mechanicResponse!),
                  ],
                ),
              ),
            ),
          ],

          // Cancel Button (for both mechanic and customer on non-cancelled appointments)
          if (widget.appointment.status != AppointmentStatus.cancelled &&
              widget.appointment.status != AppointmentStatus.completed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _cancelAppointment,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Appointment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],

          // Proposed Date (if exists)
          if (widget.appointment.proposedDate != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Proposed Alternative Date',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDateTime(widget.appointment.proposedDate!),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    if (!widget.isMechanic && widget.appointment.status == AppointmentStatus.proposed) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final success = await context.read<AppointmentProvider>().confirmProposedDate(widget.appointment.id!);
                            if (success && mounted) {
                              _showSuccessDialog('Date confirmed successfully!');
                            }
                          },
                          child: const Text('Confirm This Date'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.accepted:
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.declined:
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.proposed:
        return Colors.blue;
      case AppointmentStatus.inProgress:
        return Colors.purple;
      case AppointmentStatus.completed:
        return Colors.teal;
    }
  }
}
