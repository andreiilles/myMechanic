import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../utils/platform_utils.dart';
import '../providers/appointment_provider.dart';
import '../providers/user_provider.dart';
import '../models/appointment.dart';
import '../models/app_user.dart';
import '../services/notification_service.dart';
import 'appointment_detail_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _selectedFilter = 'all';
  bool _isLoading = true;
  AppointmentProvider? _appointmentProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService().initialize();
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

  int _getStatusPriority(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
      case AppointmentStatus.proposed:
        return 1; // New appointments first
      case AppointmentStatus.accepted:
      case AppointmentStatus.confirmed:
      case AppointmentStatus.inProgress:
        return 2; // Active appointments second
      case AppointmentStatus.cancelled:
        return 3; // Cancelled third
      case AppointmentStatus.completed:
        return 4; // Completed last
      case AppointmentStatus.declined:
        return 3; // Same as cancelled
    }
  }

  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    
    if (userProvider.currentUser != null) {
      final isMechanic = userProvider.currentUser!.userType == UserType.mechanic;
      await _appointmentProvider!.loadAppointments(
        userProvider.currentUser!.id!,
        asMechanic: isMechanic,
      );
      
      _appointmentProvider!.subscribeToAppointments(
        userProvider.currentUser!.id!,
        asMechanic: isMechanic,
      );
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _appointmentProvider?.unsubscribeFromAppointments();
    super.dispose();
  }

  List<Appointment> _getFilteredAppointments(List<Appointment> appointments) {
    List<Appointment> filtered;
    
    if (_selectedFilter == 'all') {
      filtered = appointments;
    } else {
      filtered = appointments.where((appointment) {
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
    
    // Sort by priority for 'all' filter
    if (_selectedFilter == 'all') {
      filtered.sort((a, b) {
        final priorityA = _getStatusPriority(a.status);
        final priorityB = _getStatusPriority(b.status);
        
        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }
        // If same priority, sort by date (newer first)
        return b.appointmentDate.compareTo(a.appointmentDate);
      });
    }
    
    return filtered;
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
            _buildFilterChips(),
            const Divider(height: 1),

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
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Confirmed', 'confirmed'),
          const SizedBox(width: 8),
          _buildFilterChip('Completed', 'completed'),
        ],
      ),
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
          _selectedFilter = value;
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
            _selectedFilter == 'all'
                ? 'No appointments yet'
                : 'No $_selectedFilter appointments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your appointments will appear here',
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
                  isMechanic: false,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailScreen(
                  appointment: appointment,
                  isMechanic: false,
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

              if (appointment.status == AppointmentStatus.proposed && appointment.proposedDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Alternative date proposed',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
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
