import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../models/vehicle.dart';
import '../../models/maintenance_record.dart';
import '../../providers/maintenance_provider.dart';
import '../../utils/platform_utils.dart';
import '../../widgets/adaptive_widgets.dart';
import '../../screens/add_maintenance_screen.dart';

class VehicleMaintenanceTab extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleMaintenanceTab({
    super.key,
    required this.vehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MaintenanceProvider>(
      builder: (context, maintenanceProvider, child) {
        final records = maintenanceProvider.getRecordsForVehicle(vehicle.id!);

        if (maintenanceProvider.isLoading) {
          return Center(
            child: AdaptiveLoadingIndicator(size: 20),
          );
        }

        if (records.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            _buildAddButton(context),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  return MaintenanceRecordCard(record: records[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              'Add your first maintenance record',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (PlatformUtils.isIOS)
              CupertinoButton.filled(
                onPressed: () => _navigateToAddMaintenance(context),
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
                onPressed: () => _navigateToAddMaintenance(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Record'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: PlatformUtils.isIOS
            ? CupertinoButton.filled(
                onPressed: () => _navigateToAddMaintenance(context),
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
                onPressed: () => _navigateToAddMaintenance(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Maintenance Record'),
              ),
      ),
    );
  }

  void _navigateToAddMaintenance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMaintenanceScreen(vehicle: vehicle),
      ),
    );
  }
}

class MaintenanceRecordCard extends StatelessWidget {
  final MaintenanceRecord record;

  const MaintenanceRecordCard({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildServiceInfo(context),
            if (record.description != null) ...[
              const SizedBox(height: 8),
              Text(
                record.description!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (record.serviceProvider != null) ...[
              const SizedBox(height: 8),
              _buildServiceProvider(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildServiceInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
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
          PlatformUtils.isIOS ? CupertinoIcons.speedometer : Icons.speed,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          '${record.mileageAtService} km',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildServiceProvider(BuildContext context) {
    return Row(
      children: [
        Icon(
          PlatformUtils.isIOS ? CupertinoIcons.building_2_fill : Icons.business,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          record.serviceProvider!,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
