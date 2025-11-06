import 'package:flutter/material.dart';

class SignUpMechanicInfoStep extends StatelessWidget {
  final TextEditingController businessNameController;
  final TextEditingController businessAddressController;
  final TextEditingController licenseNumberController;
  final TextEditingController hourlyRateController;
  final TextEditingController descriptionController;

  const SignUpMechanicInfoStep({
    super.key,
    required this.businessNameController,
    required this.businessAddressController,
    required this.licenseNumberController,
    required this.hourlyRateController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your mechanic profile',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name *',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your business name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: businessAddressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Business Address',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: licenseNumberController,
            decoration: const InputDecoration(
              labelText: 'License Number',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: hourlyRateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hourly Rate (\$)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
              hintText: 'Optional',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
              hintText: 'Optional - Tell customers about your services',
            ),
          ),
        ],
      ),
    );
  }
}
