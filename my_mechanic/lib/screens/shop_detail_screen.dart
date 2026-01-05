import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/mechanic.dart';
import '../utils/platform_utils.dart';
import 'book_appointment_screen.dart';

class ShopDetailScreen extends StatelessWidget {
  final Mechanic mechanic;

  const ShopDetailScreen({
    super.key,
    required this.mechanic,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(mechanic.businessName),
        ),
        child: Material(
          color: CupertinoColors.systemGroupedBackground,
          child: SafeArea(
            child: _buildContent(context),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(mechanic.businessName),
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Info Card - with icon, name, address
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
                                  Text(
                                    'Verified',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.blue,
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Shop Status Card
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
                        ? 'This shop is visible to customers and available for bookings.'
                        : 'This shop is currently not accepting new booking requests.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rating & Reviews Card
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

          // About/Description Card
          if (mechanic.description != null && mechanic.description!.isNotEmpty)
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
          if (mechanic.description != null && mechanic.description!.isNotEmpty)
            const SizedBox(height: 16),

          // Book Appointment Button
          if (PlatformUtils.isIOS)
            CupertinoButton.filled(
              onPressed: mechanic.isAcceptingClients
                  ? () => _bookAppointment(context, mechanic)
                  : null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.calendar, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Book Appointment'),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: mechanic.isAcceptingClients
                    ? () => _bookAppointment(context, mechanic)
                    : null,
                icon: const Icon(Icons.calendar_today),
                label: const Text('Book Appointment'),
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

  void _bookAppointment(BuildContext context, mechanic) {
    if (PlatformUtils.isIOS) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => BookAppointmentScreen(
            mechanicId: mechanic.userId,
            mechanicName: mechanic.businessName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookAppointmentScreen(
            mechanicId: mechanic.userId,
            mechanicName: mechanic.businessName,
          ),
        ),
      );
    }
  }
}
