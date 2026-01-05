import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/platform_utils.dart';
import '../providers/appointment_provider.dart';
import '../providers/user_provider.dart';
import '../models/appointment.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _selectedFilter = 'all'; // all, pending, confirmed, completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  Future<void> _loadAppointments() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    
    if (userProvider.currentUser != null) {
      final isMechanic = userProvider.currentUser!.userType == 'mechanic';
      await appointmentProvider.loadAppointments(
        userProvider.currentUser!.id!,
        asMechanic: isMechanic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Appointments'),
        ),
        child: Material(
          color: CupertinoColors.systemGroupedBackground,
          child: SafeArea(
            child: _buildContent(),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Confirmed', 'confirmed'),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed'),
              ],
            ),
          ),
        ),
        
        // Appointments List
        Expanded(
          child: Consumer<AppointmentProvider>(
            builder: (context, appointmentProvider, child) {
              if (appointmentProvider.isLoading) {
                return Center(
                  child: PlatformUtils.isIOS
                      ? const CupertinoActivityIndicator()
                      : const CircularProgressIndicator(),
                );
              }

              if (appointmentProvider.error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PlatformUtils.isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appointmentProvider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAppointments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final filteredAppointments = _getFilteredAppointments(appointmentProvider.appointments);

              if (filteredAppointments.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: _loadAppointments,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    return _buildAppointmentCard(filteredAppointments[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    
    if (PlatformUtils.isIOS) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected 
                ? LinearGradient(
                    colors: [
                      CupertinoColors.activeBlue,
                      CupertinoColors.activeBlue.withOpacity(0.8),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.1),
                      Colors.grey.withOpacity(0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? CupertinoColors.activeBlue.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? CupertinoColors.white : CupertinoColors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.event_note,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No appointments yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Appointments from customers will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Appointment> _getFilteredAppointments(List<Appointment> appointments) {
    if (_selectedFilter == 'all') return appointments;
    
    return appointments.where((appointment) {
      switch (_selectedFilter) {
        case 'pending':
          return appointment.status == AppointmentStatus.pending;
        case 'confirmed':
          return appointment.status == AppointmentStatus.confirmed;
        case 'completed':
          return appointment.status == AppointmentStatus.completed;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final statusColor = _getStatusColor(appointment.status);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isMechanic = userProvider.currentUser?.userType == 'mechanic';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAppointmentDetails(appointment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(
                      _getServiceIcon(appointment.serviceType),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.serviceType,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isMechanic ? 'Customer' : 'Mechanic',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(
                PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
                dateFormat.format(appointment.appointmentDate),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                PlatformUtils.isIOS ? CupertinoIcons.time : Icons.access_time,
                '${appointment.durationMinutes} minutes',
              ),
              if (appointment.estimatedCost != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  PlatformUtils.isIOS ? CupertinoIcons.money_dollar : Icons.attach_money,
                  '\$${appointment.estimatedCost!.toStringAsFixed(2)}',
                ),
              ],
              if (appointment.description != null && appointment.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  appointment.description!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.blue;
      case AppointmentStatus.inProgress:
        return Colors.purple;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getServiceIcon(String serviceType) {
    final type = serviceType.toLowerCase();
    if (type.contains('oil')) {
      return PlatformUtils.isIOS ? CupertinoIcons.drop : Icons.water_drop;
    } else if (type.contains('tire') || type.contains('wheel')) {
      return PlatformUtils.isIOS ? CupertinoIcons.circle : Icons.tire_repair;
    } else if (type.contains('brake')) {
      return PlatformUtils.isIOS ? CupertinoIcons.shield : Icons.build;
    } else if (type.contains('inspection')) {
      return PlatformUtils.isIOS ? CupertinoIcons.checkmark_shield : Icons.verified;
    }
    return PlatformUtils.isIOS ? CupertinoIcons.wrench : Icons.build;
  }

  void _showAppointmentDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                appointment.serviceType,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.status.displayName,
                  style: TextStyle(
                    color: _getStatusColor(appointment.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (appointment.description != null) ...[
                const Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(appointment.description!),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Date & Time', DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(appointment.appointmentDate)),
              _buildDetailRow('Duration', '${appointment.durationMinutes} minutes'),
              if (appointment.estimatedCost != null)
                _buildDetailRow('Estimated Cost', '\$${appointment.estimatedCost!.toStringAsFixed(2)}'),
              if (appointment.finalCost != null)
                _buildDetailRow('Final Cost', '\$${appointment.finalCost!.toStringAsFixed(2)}'),
              if (appointment.notes != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(appointment.notes!),
              ],
              if (appointment.cancellationReason != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Cancellation Reason',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  appointment.cancellationReason!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              if (appointment.status == AppointmentStatus.pending) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(appointment, AppointmentStatus.confirmed),
                        icon: const Icon(Icons.check),
                        label: const Text('Confirm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelAppointment(appointment),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (appointment.status == AppointmentStatus.confirmed) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(appointment, AppointmentStatus.inProgress),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
              if (appointment.status == AppointmentStatus.inProgress) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(appointment, AppointmentStatus.completed),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Future<void> _updateStatus(Appointment appointment, AppointmentStatus newStatus) async {
    Navigator.pop(context);
    
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final success = await appointmentProvider.updateAppointmentStatus(
      appointment.id!,
      newStatus,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment ${newStatus.displayName.toLowerCase()}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    Navigator.pop(context);

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _buildCancelDialog(),
    );

    if (reason != null) {
      final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
      final success = await appointmentProvider.updateAppointmentStatus(
        appointment.id!,
        AppointmentStatus.cancelled,
        cancellationReason: reason,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildCancelDialog() {
    final controller = TextEditingController();
    
    return AlertDialog(
      title: const Text('Cancel Appointment'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Reason for cancellation',
          hintText: 'Enter reason...',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = controller.text.trim();
            Navigator.pop(context, reason.isEmpty ? 'No reason provided' : reason);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cancel Appointment'),
        ),
      ],
    );
  }
}
