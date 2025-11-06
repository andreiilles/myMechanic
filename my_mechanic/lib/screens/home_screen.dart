import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/vehicle_provider.dart';
import '../models/vehicle.dart';
import '../utils/platform_utils.dart';
import '../widgets/vehicle_card.dart';
import '../widgets/adaptive_widgets.dart';
import '../widgets/next_inspection_card.dart';
import 'add_vehicle_screen.dart';
import 'vehicle_detail_screen.dart';

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
        navigationBar: const CupertinoNavigationBar(
          middle: Text('My Vehicles'),
        ),
        child: Material(
          color: CupertinoColors.systemGroupedBackground,
          child: SafeArea(
            child: _buildBody(),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
      ),
      body: _buildBody(),
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
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.1),
                          Colors.red.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      PlatformUtils.isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error loading vehicles',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vehicleProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
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
                    ElevatedButton.icon(
                      onPressed: () {
                        if (userProvider.currentUser != null) {
                          vehicleProvider.loadVehicles(userProvider.currentUser!.id!);
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                ],
              ),
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
            padding: const EdgeInsets.only(top: 0, bottom: 16),
            itemCount: vehicleProvider.vehicles.length + 1,
            itemBuilder: (context, index) {
              // First item is the inspection card
              if (index == 0) {
                return NextInspectionCard(
                  vehicles: vehicleProvider.vehicles,
                );
              }
              
              // Rest are vehicle cards
              final vehicle = vehicleProvider.vehicles[index - 1];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                PlatformUtils.isIOS ? CupertinoIcons.car_detailed : Icons.directions_car_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No vehicles yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first vehicle to start tracking maintenance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleDetailScreen(vehicle: vehicle),
      ),
    );
  }
}
