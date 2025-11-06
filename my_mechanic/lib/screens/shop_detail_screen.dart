import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/mechanic.dart';
import '../utils/platform_utils.dart';

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
          // Header Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mechanic.businessName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (mechanic.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Rating
                  if (mechanic.averageRating != null)
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (mechanic.averageRating ?? 0).round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${mechanic.averageRating!.toStringAsFixed(1)} (${mechanic.totalReviews} reviews)',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Status
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: mechanic.isAcceptingClients
                              ? Colors.green
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mechanic.isAcceptingClients
                            ? 'Accepting new clients'
                            : 'Not accepting clients',
                        style: TextStyle(
                          color: mechanic.isAcceptingClients
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact Information
          _buildSectionCard(
            context,
            title: 'Contact Information',
            icon: Icons.contact_page,
            children: [
              if (mechanic.businessAddress != null)
                _buildInfoRow(
                  Icons.location_on,
                  'Address',
                  mechanic.businessAddress!,
                ),
              if (mechanic.businessPhone != null)
                _buildInfoRow(
                  Icons.phone,
                  'Phone',
                  mechanic.businessPhone!,
                ),
              if (mechanic.licenseNumber != null)
                _buildInfoRow(
                  Icons.badge,
                  'License',
                  mechanic.licenseNumber!,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Services & Pricing
          _buildSectionCard(
            context,
            title: 'Services & Pricing',
            icon: Icons.build,
            children: [
              if (mechanic.hourlyRate != null)
                _buildInfoRow(
                  Icons.attach_money,
                  'Hourly Rate',
                  '\$${mechanic.hourlyRate!.toStringAsFixed(2)}/hour',
                ),
              if (mechanic.specializations.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Specializations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: mechanic.specializations.map((spec) {
                    return Chip(
                      label: Text(spec),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // About
          if (mechanic.description != null && mechanic.description!.isNotEmpty)
            _buildSectionCard(
              context,
              title: 'About',
              icon: Icons.info_outline,
              children: [
                Text(
                  mechanic.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Book Appointment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: mechanic.isAcceptingClients
                  ? () => _bookAppointment(context)
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

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _bookAppointment(BuildContext context) {
    // TODO: Implement appointment booking
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Appointment'),
        content: const Text(
          'Appointment booking feature coming soon! You can contact the shop directly using the phone number provided.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
