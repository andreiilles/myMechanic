import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../utils/platform_utils.dart';

class NextInspectionCard extends StatelessWidget {
  final List<Vehicle> vehicles;

  const NextInspectionCard({
    super.key,
    required this.vehicles,
  });

  Vehicle? _getNextInspectionVehicle() {
    final now = DateTime.now();
    Vehicle? nextVehicle;
    DateTime? earliestDate;

    for (final vehicle in vehicles) {
      final nextInspection = vehicle.nextTechnicalInspection;
      
      if (nextInspection != null) {
        // Only consider future or today's inspections
        if (nextInspection.isAfter(now.subtract(const Duration(days: 1)))) {
          if (earliestDate == null || nextInspection.isBefore(earliestDate)) {
            earliestDate = nextInspection;
            nextVehicle = vehicle;
          }
        }
      }
    }

    return nextVehicle;
  }

  int _getDaysUntilInspection(DateTime inspectionDate) {
    final now = DateTime.now();
    final difference = inspectionDate.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  Color _getUrgencyColor(int daysUntil) {
    if (daysUntil < 0) return Colors.red; // Overdue
    if (daysUntil <= 7) return Colors.orange; // Within a week
    if (daysUntil <= 30) return Colors.yellow[700]!; // Within a month
    return Colors.green; // More than a month
  }

  IconData _getUrgencyIcon(int daysUntil) {
    if (PlatformUtils.isIOS) {
      if (daysUntil < 0) return CupertinoIcons.exclamationmark_triangle_fill;
      if (daysUntil <= 7) return CupertinoIcons.clock_fill;
      if (daysUntil <= 30) return CupertinoIcons.bell_fill;
      return CupertinoIcons.checkmark_shield_fill;
    } else {
      if (daysUntil < 0) return Icons.warning_amber_rounded;
      if (daysUntil <= 7) return Icons.schedule;
      if (daysUntil <= 30) return Icons.notifications_active;
      return Icons.verified_outlined;
    }
  }

  String _getUrgencyText(int daysUntil) {
    if (daysUntil < 0) {
      return 'OVERDUE by ${daysUntil.abs()} day${daysUntil.abs() == 1 ? '' : 's'}!';
    } else if (daysUntil == 0) {
      return 'DUE TODAY!';
    } else if (daysUntil == 1) {
      return 'Due tomorrow';
    } else if (daysUntil <= 7) {
      return 'Due in $daysUntil days';
    } else if (daysUntil <= 30) {
      return 'Due in $daysUntil days';
    } else {
      final weeks = (daysUntil / 7).floor();
      return 'Due in $weeks week${weeks == 1 ? '' : 's'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextVehicle = _getNextInspectionVehicle();

    if (nextVehicle == null || nextVehicle.nextTechnicalInspection == null) {
      return const SizedBox.shrink();
    }

    final inspectionDate = nextVehicle.nextTechnicalInspection!;
    final daysUntil = _getDaysUntilInspection(inspectionDate);
    final urgencyColor = _getUrgencyColor(daysUntil);
    final urgencyIcon = _getUrgencyIcon(daysUntil);
    final urgencyText = _getUrgencyText(daysUntil);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            urgencyColor.withOpacity(0.12),
            urgencyColor.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: urgencyColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  urgencyIcon,
                  color: urgencyColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technical Inspection (ITP)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      urgencyText,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: urgencyColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  PlatformUtils.isIOS ? CupertinoIcons.info_circle_fill : Icons.info_outline,
                  size: 16,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nextVehicle.inspectionIntervalDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    PlatformUtils.isIOS ? CupertinoIcons.car_fill : Icons.directions_car,
                    size: 22,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${nextVehicle.make} ${nextVehicle.model}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${nextVehicle.year} • ${nextVehicle.licensePlate ?? nextVehicle.vin}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(
                      PlatformUtils.isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
                      size: 15,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dateFormat.format(inspectionDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
