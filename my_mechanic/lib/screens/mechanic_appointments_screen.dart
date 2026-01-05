import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/user_provider.dart';
import '../utils/platform_utils.dart';
import 'appointment_detail_screen.dart';

class MechanicAppointmentsScreen extends StatefulWidget {
  const MechanicAppointmentsScreen({super.key});

  @override
  State<MechanicAppointmentsScreen> createState() => _MechanicAppointmentsScreenState();
}

class _MechanicAppointmentsScreenState extends State<MechanicAppointmentsScreen> {
  AppointmentStatus? _selectedFilter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final userId = context.read<UserProvider>().currentUser?.id;
    debugPrint('MechanicAppointmentsScreen: userId = $userId');
    if (userId != null) {
      await context.read<AppointmentProvider>().loadAppointments(userId, asMechanic: true);
      
      // Subscribe to real-time updates (mechanics don't get notifications)
      context.read<AppointmentProvider>().subscribeToAppointments(userId, asMechanic: true);
      
      final count = context.read<AppointmentProvider>().appointments.length;
      debugPrint('MechanicAppointmentsScreen: loaded $count appointments');
    } else {
      debugPrint('MechanicAppointmentsScreen: userId is null!');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    // Unsubscribe when leaving screen
    context.read<AppointmentProvider>().unsubscribeFromAppointments();
    super.dispose();
  }

  List<Appointment> _getFilteredAppointments(List<Appointment> appointments) {
    if (_selectedFilter == null) {
      return appointments;
    }
    return appointments.where((a) => a.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('My Appointments'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _loadAppointments,
            child: const Icon(CupertinoIcons.refresh),
          ),
        ),
        child: SafeArea(
          child: _buildContent(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        if (_isLoading) {
          return Center(
            child: PlatformUtils.isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
          );
        }

        final appointments = _getFilteredAppointments(provider.appointments);

        return Column(
          children: [
            // Filter Chips
            _buildFilterChips(),
            const Divider(height: 1),

            // Appointments List
            Expanded(
              child: appointments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAppointments,
                      child: ListView.builder(
                        itemCount: appointments.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final appointment = appointments[index];
                          return _buildAppointmentCard(appointment);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('All', null),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', AppointmentStatus.pending),
          const SizedBox(width: 8),
          _buildFilterChip('Accepted', AppointmentStatus.accepted),
          const SizedBox(width: 8),
          _buildFilterChip('Confirmed', AppointmentStatus.confirmed),
          const SizedBox(width: 8),
          _buildFilterChip('In Progress', AppointmentStatus.inProgress),
          const SizedBox(width: 8),
          _buildFilterChip('Completed', AppointmentStatus.completed),
          const SizedBox(width: 8),
          _buildFilterChip('Declined', AppointmentStatus.declined),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, AppointmentStatus? status) {
    final isSelected = _selectedFilter == status;

    if (PlatformUtils.isIOS) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = status;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? CupertinoColors.white : CupertinoColors.black,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          _selectedFilter = selected ? status : null;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.event_busy,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == null
                ? 'No appointments yet'
                : 'No ${_selectedFilter!.displayName.toLowerCase()} appointments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appointments from clients will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (PlatformUtils.isIOS) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => AppointmentDetailScreen(
                  appointment: appointment,
                  isMechanic: true,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailScreen(
                  appointment: appointment,
                  isMechanic: true,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      appointment.serviceType,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(appointment.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date & Time
              Row(
                children: [
                  Icon(
                    PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(appointment.appointmentDate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    PlatformUtils.isIOS ? CupertinoIcons.clock : Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${appointment.appointmentDate.hour.toString().padLeft(2, '0')}:${appointment.appointmentDate.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Vehicle Info
              Row(
                children: [
                  Icon(
                    PlatformUtils.isIOS ? CupertinoIcons.car_fill : Icons.directions_car,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vehicle ID: ${appointment.vehicleId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Description preview
              if (appointment.description != null && appointment.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  appointment.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],

              // Proposed date indicator
              if (appointment.proposedDate != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PlatformUtils.isIOS ? CupertinoIcons.info : Icons.info_outline,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Alternative date proposed',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
