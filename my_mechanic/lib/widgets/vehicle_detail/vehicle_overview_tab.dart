import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../utils/platform_utils.dart';
import '../../widgets/share_vehicle_dialog.dart';
import 'vehicle_info_widgets.dart';

class VehicleOverviewTab extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleOverviewTab({
    super.key,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Vehicle Information'),
          const SizedBox(height: 12),
          VehicleInfoCard(
            children: [
              VehicleInfoRow(label: 'Make', value: vehicle.make),
              VehicleInfoRow(label: 'Model', value: vehicle.model),
              VehicleInfoRow(label: 'Year', value: vehicle.year.toString()),
              VehicleInfoRow(label: 'VIN', value: vehicle.vin),
              if (vehicle.licensePlate != null)
                VehicleInfoRow(label: 'License Plate', value: vehicle.licensePlate!),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Mileage & Usage'),
          const SizedBox(height: 12),
          VehicleInfoCard(
            children: [
              VehicleInfoRow(
                label: 'Current Mileage',
                value: '${vehicle.currentMileage.toStringAsFixed(0)} km',
              ),
              VehicleInfoRow(
                label: 'Added',
                value: _formatDate(vehicle.createdAt),
              ),
              VehicleInfoRow(
                label: 'Last Updated',
                value: _formatDate(vehicle.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Quick Stats'),
          const SizedBox(height: 12),
          _buildQuickStats(context),
          const SizedBox(height: 24),
          _buildSectionTitle('Shared With'),
          const SizedBox(height: 12),
          _buildSharedUsers(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer<MaintenanceProvider>(
      builder: (context, maintenanceProvider, child) {
        final records = maintenanceProvider.getRecordsForVehicle(vehicle.id!);
        final totalCost = maintenanceProvider.getTotalCostForVehicle(vehicle.id!);
        final upcomingCount = maintenanceProvider.getUpcomingMaintenanceCount(vehicle.id!);

        return Row(
          children: [
            Expanded(
              child: VehicleStatCard(
                icon: Icons.build,
                title: 'Services',
                value: records.length.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VehicleStatCard(
                icon: Icons.warning_amber,
                title: 'Upcoming',
                value: upcomingCount.toString(),
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VehicleStatCard(
                icon: Icons.attach_money,
                title: 'Total Cost',
                value: '\$${totalCost.toStringAsFixed(0)}',
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSharedUsers(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<VehicleProvider>().getVehicleUsers(vehicle.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final users = snapshot.data!;

        if (users.length <= 1) {
          return _buildNoSharedUsers(context);
        }

        return _buildSharedUsersList(context, users);
      },
    );
  }

  Widget _buildNoSharedUsers(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              PlatformUtils.isIOS ? CupertinoIcons.person : Icons.person,
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
              onPressed: () => _showShareVehicleDialog(context),
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedUsersList(BuildContext context, List<Map<String, dynamic>> users) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < users.length; i++) ...[
            _buildUserCard(context, users[i]),
            if (i < users.length - 1) const Divider(height: 1),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: () => _showShareVehicleDialog(context),
              icon: Icon(PlatformUtils.isIOS ? CupertinoIcons.person_add : Icons.person_add),
              label: const Text('Add User'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> userData) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showShareVehicleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ShareVehicleDialog(vehicle: vehicle),
    );
  }
}
