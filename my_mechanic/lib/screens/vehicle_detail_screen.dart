import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../utils/platform_utils.dart';
import '../widgets/adaptive_widgets.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          middle: Text('${widget.vehicle.year} ${widget.vehicle.make}'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showOptionsMenu,
            child: const Icon(CupertinoIcons.ellipsis),
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicle.year} ${widget.vehicle.make}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editVehicle,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteVehicle,
          ),
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
          // Vehicle Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PlatformUtils.isIOS ? CupertinoIcons.car_detailed : Icons.directions_car,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Vehicle Name
          Text(
            '${widget.vehicle.year} ${widget.vehicle.make}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.vehicle.model,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
          if (widget.vehicle.licensePlate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.vehicle.licensePlate!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    if (PlatformUtils.isIOS) {
      return Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: _tabController.index,
          onValueChanged: (value) {
            if (value != null) {
              setState(() {
                _tabController.animateTo(value);
              });
            }
          },
          children: const {
            0: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Overview'),
            ),
            1: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Maintenance'),
            ),
            2: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Documents'),
            ),
          },
        ),
      );
    }

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
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
            _buildInfoRow(
              'Added',
              _formatDate(widget.vehicle.createdAt),
            ),
            _buildInfoRow(
              'Last Updated',
              _formatDate(widget.vehicle.updatedAt),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Quick Stats'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.build,
                  label: 'Services',
                  value: '0', // TODO: Connect to actual data
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.warning_amber,
                  label: 'Upcoming',
                  value: '0', // TODO: Connect to actual data
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  label: 'Total Cost',
                  value: '\$0', // TODO: Connect to actual data
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTab() {
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maintenance tracking coming soon',
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

  Widget _buildDocumentsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PlatformUtils.isIOS ? CupertinoIcons.doc : Icons.description,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No documents',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Store insurance, registration, and other documents',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
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
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit vehicle feature coming soon')),
    );
  }

  void _deleteVehicle() {
    showAdaptiveAlertDialog(
      context: context,
      title: 'Delete Vehicle',
      content: 'Are you sure you want to delete this vehicle? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    ).then((confirmed) async {
      if (confirmed == true) {
        final vehicleProvider = context.read<VehicleProvider>();
        final success = await vehicleProvider.deleteVehicle(widget.vehicle.id!);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vehicle deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(); // Go back to home screen
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(vehicleProvider.error ?? 'Failed to delete vehicle'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }
}
