import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/platform_utils.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String _selectedFilter = 'all'; // all, pending, confirmed, completed

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Appointments'),
        ),
        child: SafeArea(
          child: _buildContent(),
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
          child: _buildEmptyState(),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? CupertinoColors.white : CupertinoColors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            Icon(
              PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.event_note,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No appointments yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
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

  // TODO: This will be used when we have real appointment data
  Widget _buildAppointmentCard(dynamic appointment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            PlatformUtils.isIOS ? CupertinoIcons.person : Icons.person,
          ),
        ),
        title: Text('Customer Name'), // appointment.customerName
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Vehicle: Make Model'), // appointment.vehicle
            const SizedBox(height: 2),
            Text('Date & Time'), // appointment.dateTime
          ],
        ),
        trailing: Icon(
          PlatformUtils.isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right,
        ),
        onTap: () {
          // TODO: Navigate to appointment details
        },
      ),
    );
  }
}
