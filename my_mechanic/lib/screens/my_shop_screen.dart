import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/platform_utils.dart';
import 'edit_shop_screen.dart';

class MyShopScreen extends StatelessWidget {
  const MyShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final mechanic = userProvider.mechanicProfile;

    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('My Shop'),
        ),
        child: SafeArea(
          child: _buildContent(context, mechanic),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shop'),
      ),
      body: _buildContent(context, mechanic),
    );
  }

  Widget _buildContent(BuildContext context, mechanic) {
    if (mechanic == null) {
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
                      Colors.orange.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  PlatformUtils.isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.error_outline,
                  size: 64,
                  color: Colors.orange[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Mechanic profile not found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          PlatformUtils.isIOS ? CupertinoIcons.building_2_fill : Icons.business,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mechanic.businessName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (mechanic.isVerified)
                              Row(
                                children: [
                                  Icon(
                                    PlatformUtils.isIOS ? CupertinoIcons.checkmark_seal_fill : Icons.verified,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (mechanic.businessAddress != null) ...[
                    _buildInfoRow(
                      context,
                      PlatformUtils.isIOS ? CupertinoIcons.location_solid : Icons.location_on,
                      mechanic.businessAddress!,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (mechanic.businessPhone != null) ...[
                    _buildInfoRow(
                      context,
                      PlatformUtils.isIOS ? CupertinoIcons.phone_fill : Icons.phone,
                      mechanic.businessPhone!,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (mechanic.licenseNumber != null) ...[
                    _buildInfoRow(
                      context,
                      PlatformUtils.isIOS ? CupertinoIcons.doc_text_fill : Icons.badge,
                      'License: ${mechanic.licenseNumber}',
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (mechanic.hourlyRate != null) ...[
                    _buildInfoRow(
                      context,
                      PlatformUtils.isIOS ? CupertinoIcons.money_dollar_circle_fill : Icons.attach_money,
                      '${mechanic.hourlyRate} RON/hour',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        mechanic.isAcceptingClients
                            ? (PlatformUtils.isIOS ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle)
                            : (PlatformUtils.isIOS ? CupertinoIcons.pause_circle_fill : Icons.pause_circle),
                        color: mechanic.isAcceptingClients ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          mechanic.isAcceptingClients
                              ? 'Accepting New Clients'
                              : 'Not Accepting New Clients',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: mechanic.isAcceptingClients ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mechanic.isAcceptingClients
                        ? 'Your shop is visible to customers and available for bookings.'
                        : 'Your shop is hidden from new booking requests.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rating Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating & Reviews',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        PlatformUtils.isIOS ? CupertinoIcons.star_fill : Icons.star,
                        color: Colors.amber,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (mechanic.averageRating ?? 0.0).toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${mechanic.totalReviews ?? 0} reviews)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Services & Pricing Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        PlatformUtils.isIOS ? CupertinoIcons.wrench_fill : Icons.build,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Services & Pricing',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (mechanic.businessPhone != null) ...[
                    _buildInfoRow(
                      context,
                      PlatformUtils.isIOS ? CupertinoIcons.phone_fill : Icons.phone,
                      mechanic.businessPhone!,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (mechanic.licenseNumber != null) ...[
                    _buildInfoRow(
                      context,
                      PlatformUtils.isIOS ? CupertinoIcons.doc_text_fill : Icons.badge,
                      'License: ${mechanic.licenseNumber}',
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (mechanic.hourlyRate != null) ...[
                    _buildInfoRow(
                      context,
                      PlatformUtils.isIOS ? CupertinoIcons.money_dollar_circle_fill : Icons.attach_money,
                      '${mechanic.hourlyRate} RON/hour',
                    ),
                  ],
                  if (mechanic.specializations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Specializations',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: mechanic.specializations.map((spec) {
                        return Chip(
                          label: Text(spec),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description Card
          if (mechanic.description != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mechanic.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Action Buttons
          if (PlatformUtils.isIOS)
            CupertinoButton.filled(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => EditShopScreen(mechanic: mechanic),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.pencil, size: 20),
                  SizedBox(width: 8),
                  Text('Edit Shop Info'),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditShopScreen(mechanic: mechanic),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Shop Info'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
