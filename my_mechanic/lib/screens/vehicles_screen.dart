import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/platform_utils.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('My Vehicles'),
        ),
        child: SafeArea(
          child: _VehiclesContent(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
      ),
      body: const _VehiclesContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add vehicle screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _VehiclesContent extends StatelessWidget {
  const _VehiclesContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PlatformUtils.isIOS ? CupertinoIcons.car_detailed : Icons.directions_car,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No vehicles yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first vehicle to get started',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
