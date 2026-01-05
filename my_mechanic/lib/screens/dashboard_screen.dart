import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/app_user.dart';
import '../utils/platform_utils.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Home'),
        ),
        child: Material(
          color: CupertinoColors.systemGroupedBackground,
          child: SafeArea(
            child: _buildContent(context, user?.firstName ?? 'there'),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: _buildContent(context, user?.firstName ?? 'there'),
    );
  }

  Widget _buildContent(BuildContext context, String firstName) {
    final userProvider = context.watch<UserProvider>();
    final isMechanic = userProvider.currentUser?.userType == UserType.mechanic;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          PlatformUtils.isIOS 
                              ? CupertinoIcons.hand_raised_fill 
                              : Icons.waving_hand,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              firstName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isMechanic
                        ? 'Manage your shop and appointments from here.'
                        : 'Keep track of your vehicles and find nearby mechanics.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions Section
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (isMechanic) ..._buildMechanicActions(context) else ..._buildCustomerActions(context),
        ],
      ),
    );
  }

  List<Widget> _buildCustomerActions(BuildContext context) {
    return [
      _buildActionCard(
        context: context,
        title: 'My Vehicles',
        subtitle: 'View and manage your vehicles',
        icon: PlatformUtils.isIOS ? CupertinoIcons.car_detailed : Icons.directions_car,
        color: Colors.blue,
        onTap: () => onNavigateToTab?.call(2),
      ),
      const SizedBox(height: 12),
      _buildActionCard(
        context: context,
        title: 'Find Shops',
        subtitle: 'Discover nearby mechanic shops',
        icon: PlatformUtils.isIOS ? CupertinoIcons.map_pin_ellipse : Icons.location_on,
        color: Colors.green,
        onTap: () => onNavigateToTab?.call(1),
      ),
      const SizedBox(height: 12),
      _buildActionCard(
        context: context,
        title: 'Profile',
        subtitle: 'View and edit your profile',
        icon: PlatformUtils.isIOS ? CupertinoIcons.person_circle : Icons.account_circle,
        color: Colors.orange,
        onTap: () => onNavigateToTab?.call(3),
      ),
    ];
  }

  List<Widget> _buildMechanicActions(BuildContext context) {
    return [
      _buildActionCard(
        context: context,
        title: 'My Shop',
        subtitle: 'Manage your shop details',
        icon: PlatformUtils.isIOS ? CupertinoIcons.building_2_fill : Icons.business,
        color: Colors.blue,
        onTap: () => onNavigateToTab?.call(1),
      ),
      const SizedBox(height: 12),
      _buildActionCard(
        context: context,
        title: 'Appointments',
        subtitle: 'View and manage bookings',
        icon: PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
        color: Colors.green,
        onTap: () => onNavigateToTab?.call(2),
      ),
      const SizedBox(height: 12),
      _buildActionCard(
        context: context,
        title: 'Profile',
        subtitle: 'View and edit your profile',
        icon: PlatformUtils.isIOS ? CupertinoIcons.person_circle : Icons.account_circle,
        color: Colors.orange,
        onTap: () => onNavigateToTab?.call(3),
      ),
    ];
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                PlatformUtils.isIOS 
                    ? CupertinoIcons.chevron_right 
                    : Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
