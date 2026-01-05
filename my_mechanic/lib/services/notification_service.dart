import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to appointment details
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> showAppointmentStatusNotification({
    required String title,
    required String body,
    String? appointmentId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'appointment_updates',
      'Appointment Updates',
      channelDescription: 'Notifications for appointment status changes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      appointmentId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      details,
      payload: appointmentId,
    );
  }

  Future<void> showAppointmentAcceptedNotification(String mechanicName) async {
    await showAppointmentStatusNotification(
      title: 'Appointment Accepted',
      body: '$mechanicName has accepted your appointment request!',
    );
  }

  Future<void> showAppointmentDeclinedNotification(String mechanicName, String? reason) async {
    await showAppointmentStatusNotification(
      title: 'Appointment Declined',
      body: '$mechanicName declined your appointment${reason != null ? ': $reason' : '.'}',
    );
  }

  Future<void> showAlternativeDateProposedNotification(String mechanicName, DateTime proposedDate) async {
    final dateStr = '${proposedDate.day}/${proposedDate.month}/${proposedDate.year} at ${proposedDate.hour.toString().padLeft(2, '0')}:${proposedDate.minute.toString().padLeft(2, '0')}';
    await showAppointmentStatusNotification(
      title: 'Alternative Date Proposed',
      body: '$mechanicName proposed a new date: $dateStr',
    );
  }

  Future<void> showAppointmentConfirmedNotification() async {
    await showAppointmentStatusNotification(
      title: 'Appointment Confirmed',
      body: 'Your appointment has been confirmed!',
    );
  }

  Future<void> showAppointmentCompletedNotification() async {
    await showAppointmentStatusNotification(
      title: 'Service Completed',
      body: 'Your service has been completed. Please leave a review!',
    );
  }

  Future<void> showAppointmentCancelledNotification(String cancelledBy, String? reason) async {
    await showAppointmentStatusNotification(
      title: 'Appointment Cancelled',
      body: '$cancelledBy cancelled the appointment${reason != null && reason.isNotEmpty ? ': $reason' : '.'}',
    );
  }
}
