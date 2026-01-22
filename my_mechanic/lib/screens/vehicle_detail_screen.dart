import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:image_picker/image_picker.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../providers/vehicle_provider.dart';
import '../providers/maintenance_provider.dart';
import '../utils/platform_utils.dart';
import '../widgets/adaptive_widgets.dart';
import '../widgets/share_vehicle_dialog.dart';
import '../widgets/vehicle_detail/vehicle_documents_tab.dart';
import '../screens/add_maintenance_screen.dart';
// Make sure the path above is correct and that AddMaintenanceScreen is defined and exported in that file.

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load maintenance records
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final maintenanceProvider = context.read<MaintenanceProvider>();
      maintenanceProvider.loadRecords(widget.vehicle.id!);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('${widget.vehicle.make} ${widget.vehicle.model}'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showOptionsMenu,
            child: const Icon(CupertinoIcons.ellipsis),
          ),
        ),
        child: SafeArea(child: _buildBody()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle.make} ${widget.vehicle.model}'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editVehicle),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteVehicle),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildVehicleHeader(),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildMaintenanceTab(),
              _buildDocumentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Vehicle Image/Icon with shared badge and upload option
          Stack(
            children: [
              GestureDetector(
                onTap: _showImageOptions,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child:
                        widget.vehicle.imageUrl != null &&
                            widget.vehicle.imageUrl!.isNotEmpty
                        ? Image.network(
                            widget.vehicle.imageUrl!,
                            key: ValueKey(widget.vehicle.imageUrl),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: PlatformUtils.isIOS
                                    ? const CupertinoActivityIndicator()
                                    : const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                PlatformUtils.isIOS
                                    ? CupertinoIcons.car_detailed
                                    : Icons.directions_car,
                                size: 60,
                                color: Colors.white,
                              );
                            },
                          )
                        : Icon(
                            PlatformUtils.isIOS
                                ? CupertinoIcons.car_detailed
                                : Icons.directions_car,
                            size: 60,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
              // Camera icon for adding/changing photo
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _showImageOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      PlatformUtils.isIOS
                          ? CupertinoIcons.camera_fill
                          : Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Show "Shared" badge if vehicle is shared
              FutureBuilder<bool>(
                future: context.read<VehicleProvider>().isVehicleShared(
                  widget.vehicle.id!,
                ),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          PlatformUtils.isIOS
                              ? CupertinoIcons.person_2_fill
                              : Icons.people,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vehicle Name - Make Model
          Text(
            '${widget.vehicle.make} ${widget.vehicle.model}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              decoration:
                  TextDecoration.none, // Explicitly remove any underline
            ),
          ),
          const SizedBox(height: 4),
          // Year
          Text(
            '${widget.vehicle.year}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              decoration:
                  TextDecoration.none, // Explicitly remove any underline
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    debugPrint('Building TabBar - Platform.isIOS: ${Platform.isIOS}');
    debugPrint('Building TabBar - PlatformUtils.isIOS: ${PlatformUtils.isIOS}');

    if (Platform.isIOS) {
      debugPrint('Using CupertinoSlidingSegmentedControl for iOS');
      // Use AnimatedBuilder to rebuild whenever the tab controller animation changes
      return AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          // Get the current index, accounting for animation progress
          final int currentIndex = _tabController.animation!.value.round();

          return Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: currentIndex,
              backgroundColor: CupertinoColors.systemGrey5.resolveFrom(context),
              thumbColor: CupertinoColors.systemBlue,
              onValueChanged: (value) {
                if (value != null) {
                  _tabController.animateTo(value);
                }
              },
              children: {
                0: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Text(
                    'Overview',
                    style: TextStyle(
                      color: currentIndex == 0
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      fontWeight: currentIndex == 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                1: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Text(
                    'Maintenance',
                    style: TextStyle(
                      color: currentIndex == 1
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      fontWeight: currentIndex == 1
                          ? FontWeight.w600
                          : FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                2: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Text(
                    'Documents',
                    style: TextStyle(
                      color: currentIndex == 2
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      fontWeight: currentIndex == 2
                          ? FontWeight.w600
                          : FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              },
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicator: const BoxDecoration(color: Colors.transparent),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Maintenance'),
          Tab(text: 'Documents'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Vehicle Information'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow('Make', widget.vehicle.make),
            _buildInfoRow('Model', widget.vehicle.model),
            _buildInfoRow('Year', widget.vehicle.year.toString()),
            _buildInfoRow('VIN', widget.vehicle.vin),
            if (widget.vehicle.licensePlate != null)
              _buildInfoRow('License Plate', widget.vehicle.licensePlate!),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Mileage & Usage'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow(
              'Current Mileage',
              '${widget.vehicle.currentMileage.toStringAsFixed(0)} km',
            ),
            if (widget.vehicle.lastTechnicalInspection != null)
              _buildInfoRow(
                'Last Inspection',
                _formatDate(widget.vehicle.lastTechnicalInspection!),
              ),
            _buildInfoRow('Added', _formatDate(widget.vehicle.createdAt)),
            _buildInfoRow(
              'Last Updated',
              _formatDate(widget.vehicle.updatedAt),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Quick Stats'),
          const SizedBox(height: 12),
          Consumer<MaintenanceProvider>(
            builder: (context, maintenanceProvider, child) {
              final records = maintenanceProvider.getRecordsForVehicle(
                widget.vehicle.id!,
              );
              final totalCost = maintenanceProvider.getTotalCostForVehicle(
                widget.vehicle.id!,
              );
              final upcomingCount = maintenanceProvider
                  .getUpcomingMaintenanceCount(widget.vehicle.id!);

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.build,
                      label: 'Services',
                      value: records.length.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.warning_amber,
                      label: 'Upcoming',
                      value: upcomingCount.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.attach_money,
                      label: 'Total Cost',
                      value: '\$${totalCost.toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Shared users section
          _buildSectionTitle('Shared With'),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: context.read<VehicleProvider>().getVehicleUsers(
              widget.vehicle.id!,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const SizedBox.shrink();
              }

              final users = snapshot.data!;

              if (users.length <= 1) {
                // Only owner, no sharing
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          PlatformUtils.isIOS
                              ? CupertinoIcons.person
                              : Icons.person,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This vehicle is not shared',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        TextButton(
                          onPressed: _showShareVehicleDialog,
                          child: const Text('Share'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Card(
                child: Column(
                  children: [
                    for (var i = 0; i < users.length; i++) ...[
                      _buildUserCard(users[i]),
                      if (i < users.length - 1) const Divider(height: 1),
                    ],
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextButton.icon(
                        onPressed: _showShareVehicleDialog,
                        icon: Icon(
                          PlatformUtils.isIOS
                              ? CupertinoIcons.person_add
                              : Icons.person_add,
                        ),
                        label: const Text('Add User'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildUserCard(Map<String, dynamic> userData) {
    final relationship = userData['relationship'] as String?;
    final userInfo = userData['users'] as Map<String, dynamic>?;

    if (userInfo == null) return const SizedBox.shrink();

    final firstName = userInfo['first_name'] as String? ?? '';
    final lastName = userInfo['last_name'] as String? ?? '';
    final email = userInfo['email'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Text(
          firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(fullName.isNotEmpty ? fullName : email),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fullName.isNotEmpty && email.isNotEmpty)
            Text(
              email,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          Text(
            _formatRelationship(relationship ?? 'member'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelationship(String relationship) {
    switch (relationship) {
      case 'owner':
        return 'Owner';
      case 'family_member':
        return 'Family Member';
      case 'shared':
        return 'Shared Access';
      default:
        return relationship;
    }
  }

  void _showShareVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) => ShareVehicleDialog(vehicle: widget.vehicle),
    );
  }

  Widget _buildMaintenanceTab() {
    return Consumer<MaintenanceProvider>(
      builder: (context, maintenanceProvider, child) {
        final records = maintenanceProvider.getRecordsForVehicle(
          widget.vehicle.id!,
        );

        if (maintenanceProvider.isLoading) {
          return Center(child: AdaptiveLoadingIndicator(size: 20));
        }

        if (records.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PlatformUtils.isIOS ? CupertinoIcons.wrench : Icons.build,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No maintenance records',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first maintenance record',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (PlatformUtils.isIOS)
                    CupertinoButton.filled(
                      onPressed: _navigateToAddMaintenance,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.add, size: 20),
                          SizedBox(width: 8),
                          Text('Add Record'),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _navigateToAddMaintenance,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Record'),
                    ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Add button at the top
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: PlatformUtils.isIOS
                    ? CupertinoButton.filled(
                        onPressed: _navigateToAddMaintenance,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.add, size: 20),
                            SizedBox(width: 8),
                            Text('Add Maintenance Record'),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _navigateToAddMaintenance,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Maintenance Record'),
                      ),
              ),
            ),
            // Records list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return _buildMaintenanceCard(record);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaintenanceCard(MaintenanceRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    record.type.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '\$${record.cost.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  PlatformUtils.isIOS
                      ? CupertinoIcons.calendar
                      : Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(record.serviceDate),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(
                  PlatformUtils.isIOS
                      ? CupertinoIcons.speedometer
                      : Icons.speed,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${record.mileageAtService} km',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (record.description != null) ...[
              const SizedBox(height: 8),
              Text(record.description!, style: const TextStyle(fontSize: 14)),
            ],
            if (record.serviceProvider != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    PlatformUtils.isIOS
                        ? CupertinoIcons.building_2_fill
                        : Icons.business,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.serviceProvider!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return VehicleDocumentsTab(vehicle: widget.vehicle);
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editVehicle();
            },
            child: const Text('Edit Vehicle'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteVehicle();
            },
            isDestructiveAction: true,
            child: const Text('Delete Vehicle'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _editVehicle() {
    // TODO: Navigate to edit vehicle screen
    _showMessage('Edit vehicle feature coming soon', isError: false);
  }

  void _navigateToAddMaintenance() async {
    try {
      debugPrint(
        'Navigating to Add Maintenance screen for vehicle: ${widget.vehicle.id}',
      );

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddMaintenanceScreen(vehicle: widget.vehicle),
        ),
      );

      debugPrint('Returned from Add Maintenance screen with result: $result');

      // Reload maintenance records if a record was added
      if (result == true && mounted) {
        final maintenanceProvider = context.read<MaintenanceProvider>();
        maintenanceProvider.loadRecords(widget.vehicle.id!);
      }
    } catch (e, stackTrace) {
      debugPrint('Error navigating to Add Maintenance: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        _showMessage('Error: ${e.toString()}', isError: true);
      }
    }
  }

  void _deleteVehicle() {
    showAdaptiveAlertDialog(
      context: context,
      title: 'Delete Vehicle',
      content:
          'Are you sure you want to delete this vehicle? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    ).then((confirmed) async {
      if (confirmed == true) {
        final vehicleProvider = context.read<VehicleProvider>();
        final success = await vehicleProvider.deleteVehicle(widget.vehicle.id!);

        if (mounted) {
          if (success) {
            Navigator.of(context).pop(); // Go back to home screen

            // Show success message
            if (PlatformUtils.isIOS) {
              // For iOS, we can't show SnackBar since we're using CupertinoPageScaffold
              // The success is implicit by going back
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vehicle deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            // Show error message
            _showMessage(
              vehicleProvider.error ?? 'Failed to delete vehicle',
              isError: true,
            );
          }
        }
      }
    });
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

  void _showImageOptions() {
    if (PlatformUtils.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: const Text('Vehicle Photo'),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: const Text('Take Photo'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: const Text('Choose from Gallery'),
            ),
            if (widget.vehicle.imageUrl != null &&
                widget.vehicle.imageUrl!.isNotEmpty)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _removeImage();
                },
                isDestructiveAction: true,
                child: const Text('Remove Photo'),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (widget.vehicle.imageUrl != null &&
                    widget.vehicle.imageUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeImage();
                    },
                  ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (!mounted) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: PlatformUtils.isIOS
              ? CupertinoAlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CupertinoActivityIndicator(),
                      SizedBox(height: 16),
                      Text('Uploading image...'),
                    ],
                  ),
                )
              : AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Uploading image...'),
                    ],
                  ),
                ),
        ),
      );

      // Upload image and update vehicle
      final vehicleProvider = context.read<VehicleProvider>();
      debugPrint('Starting image upload...');
      final success = await vehicleProvider.uploadVehicleImage(
        widget.vehicle.id!,
        pickedFile.path,
      );
      debugPrint('Upload completed. Success: $success');

      if (!mounted) {
        debugPrint('Widget not mounted, returning');
        return;
      }

      // Close loading dialog
      debugPrint('Closing loading dialog...');
      Navigator.of(context, rootNavigator: true).pop();
      debugPrint('Dialog closed');

      // Show success/error message
      if (success) {
        // Refresh the vehicle to show new image
        await vehicleProvider.getVehicleById(widget.vehicle.id!);
        if (mounted) {
          setState(() {});
        }

        _showMessage('Vehicle photo updated successfully', isError: false);
      } else {
        _showMessage(
          vehicleProvider.error ?? 'Failed to upload image',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        // Try to close loading dialog if it's open
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {
          // Dialog might not be open
        }

        _showMessage('Error: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _removeImage() async {
    final confirmed = await showAdaptiveAlertDialog(
      context: context,
      title: 'Remove Photo',
      content: 'Are you sure you want to remove the vehicle photo?',
      confirmText: 'Remove',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true) return;

    if (!mounted) return;

    try {
      final vehicleProvider = context.read<VehicleProvider>();
      final success = await vehicleProvider.removeVehicleImage(
        widget.vehicle.id!,
      );

      if (!mounted) return;

      if (success) {
        setState(() {});

        _showMessage('Vehicle photo removed', isError: false);
      } else {
        _showMessage(
          vehicleProvider.error ?? 'Failed to remove image',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error removing image: $e');
      if (mounted) {
        _showMessage('Error: ${e.toString()}', isError: true);
      }
    }
  }
}
