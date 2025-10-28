import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle.dart';
import '../utils/platform_utils.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/adaptive_widgets.dart';
import 'add_vehicle_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load vehicles when the screen is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final vehicleProvider = context.read<VehicleProvider>();
      if (userProvider.currentUser != null) {
        vehicleProvider.loadVehicles(userProvider.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('My Vehicles'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showLogoutDialog,
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
        title: const Text('My Vehicles'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: Consumer<VehicleProvider>(
        builder: (context, vehicleProvider, _) {
          if (vehicleProvider.vehicles.isEmpty && !vehicleProvider.isLoading) {
            return FloatingActionButton.extended(
              onPressed: _navigateToAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            );
          }
          return FloatingActionButton(
            onPressed: _navigateToAddVehicle,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return Consumer2<VehicleProvider, UserProvider>(
      builder: (context, vehicleProvider, userProvider, child) {
        if (vehicleProvider.isLoading) {
          return Center(
            child: AdaptiveLoadingIndicator(size: 20),
          );
        }

        if (vehicleProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PlatformUtils.isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading vehicles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  vehicleProvider.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (PlatformUtils.isIOS)
                  CupertinoButton.filled(
                    onPressed: () {
                      if (userProvider.currentUser != null) {
                        vehicleProvider.loadVehicles(userProvider.currentUser!.id!);
                      }
                    },
                    child: const Text('Retry'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      if (userProvider.currentUser != null) {
                        vehicleProvider.loadVehicles(userProvider.currentUser!.id!);
                      }
                    },
                    child: const Text('Retry'),
                  ),
              ],
            ),
          );
        }

        if (vehicleProvider.vehicles.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (userProvider.currentUser != null) {
              await vehicleProvider.loadVehicles(userProvider.currentUser!.id!);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicleProvider.vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicleProvider.vehicles[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: VehicleCard(
                  vehicle: vehicle,
                  onTap: () => _navigateToVehicleDetail(vehicle),
                ),
              );
            },
          ),
        );
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
              PlatformUtils.isIOS ? CupertinoIcons.car_detailed : Icons.directions_car_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No vehicles yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first vehicle to start tracking maintenance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (PlatformUtils.isIOS)
              CupertinoButton.filled(
                onPressed: _navigateToAddVehicle,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add, size: 20),
                    SizedBox(width: 8),
                    Text('Add Vehicle'),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _navigateToAddVehicle,
                icon: const Icon(Icons.add),
                label: const Text('Add Vehicle'),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddVehicle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddVehicleScreen(),
      ),
    );
  }

  void _navigateToVehicleDetail(Vehicle vehicle) {
    // TODO: Navigate to vehicle detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected ${vehicle.make} ${vehicle.model}')),
    );
  }

  void _showLogoutDialog() {
    showAdaptiveAlertDialog(
      context: context,
      title: 'Logout',
      content: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      cancelText: 'Cancel',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<AuthProvider>().signOut();
      }
    });
  }
}
