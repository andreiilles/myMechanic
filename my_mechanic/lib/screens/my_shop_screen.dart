import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/platform_utils.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PlatformUtils.isIOS ? CupertinoIcons.exclamationmark_triangle : Icons.error_outline,
              size: 64,
              color: Colors.orange[300],
            ),
            const SizedBox(height: 16),
            const Text('Mechanic profile not found'),
          ],
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
                      Icon(
                        PlatformUtils.isIOS ? CupertinoIcons.building_2_fill : Icons.business,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
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
                      '\$${mechanic.hourlyRate}/hour',
                    ),
                  ],
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
                        mechanic.rating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${mechanic.totalReviews} reviews)',
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
                // TODO: Navigate to edit shop screen
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
                  // TODO: Navigate to edit shop screen
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Shop Info'),
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
