import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class AppointmentProvider with ChangeNotifier {
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _appointmentChannel;
  String? _currentUserId;
  bool _isCustomer = true;

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Load appointments for current user (as customer or mechanic)
  Future<void> loadAppointments(String userId, {bool asMechanic = false}) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('Loading appointments for userId: $userId, asMechanic: $asMechanic');

      final response = asMechanic
          ? await SupabaseService.client
              .from('appointments')
              .select('''
                *,
                customer:users!appointments_customer_id_fkey(id, first_name, last_name, email, phone_number),
                mechanic:users!appointments_mechanic_id_fkey(id, first_name, last_name, email, phone_number),
                vehicles(id, make, model, year, vin, license_plate, current_mileage, color)
              ''')
              .eq('mechanic_id', userId)
              .order('appointment_date', ascending: true)
          : await SupabaseService.client
              .from('appointments')
              .select('''
                *,
                customer:users!appointments_customer_id_fkey(id, first_name, last_name, email, phone_number),
                mechanic:users!appointments_mechanic_id_fkey(id, first_name, last_name, email, phone_number),
                vehicles(id, make, model, year, vin, license_plate, current_mileage, color)
              ''')
              .eq('customer_id', userId)
              .order('appointment_date', ascending: true);

      debugPrint('Loaded ${(response as List).length} appointments');
      
      // Debug: print first appointment raw data
      if ((response as List).isNotEmpty) {
        debugPrint('First appointment raw data: ${(response as List).first}');
      }

      _appointments = (response as List)
          .map((json) => Appointment.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load appointments: ${e.toString()}');
      debugPrint('Error loading appointments: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new appointment
  Future<bool> createAppointment(Appointment appointment) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await SupabaseService.client
          .from('appointments')
          .insert(appointment.toJson(excludeId: true))
          .select('''
            *,
            customer:users!appointments_customer_id_fkey(id, first_name, last_name, email, phone_number),
            mechanic:users!appointments_mechanic_id_fkey(id, first_name, last_name, email, phone_number),
            vehicles(id, make, model, year, vin, license_plate, current_mileage, color)
          ''')
          .single();

      final newAppointment = Appointment.fromJson(response);
      _appointments.insert(0, newAppointment);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create appointment: ${e.toString()}');
      debugPrint('Error creating appointment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update appointment
  Future<bool> updateAppointment(Appointment appointment) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedAppointment = appointment.copyWith(updatedAt: DateTime.now());
      await SupabaseService.client
          .from('appointments')
          .update(updatedAppointment.toJson(excludeId: true))
          .eq('id', appointment.id!);

      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = updatedAppointment;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update appointment: ${e.toString()}');
      debugPrint('Error updating appointment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update appointment status
  Future<bool> updateAppointmentStatus(String appointmentId, AppointmentStatus status, {String? cancellationReason}) async {
    try {
      _setLoading(true);
      _clearError();

      final updateData = {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == AppointmentStatus.cancelled && cancellationReason != null) {
        updateData['cancellation_reason'] = cancellationReason;
      }

      await SupabaseService.client
          .from('appointments')
          .update(updateData)
          .eq('id', appointmentId);

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: status,
          cancellationReason: cancellationReason,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update status: ${e.toString()}');
      debugPrint('Error updating appointment status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete appointment
  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      _setLoading(true);
      _clearError();

      await SupabaseService.client
          .from('appointments')
          .delete()
          .eq('id', appointmentId);

      _appointments.removeWhere((a) => a.id == appointmentId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete appointment: ${e.toString()}');
      debugPrint('Error deleting appointment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get appointments by status
  List<Appointment> getAppointmentsByStatus(AppointmentStatus status) {
    return _appointments.where((a) => a.status == status).toList();
  }

  // Get upcoming appointments
  List<Appointment> getUpcomingAppointments() {
    final now = DateTime.now();
    return _appointments
        .where((a) => 
          a.appointmentDate.isAfter(now) && 
          a.status != AppointmentStatus.cancelled &&
          a.status != AppointmentStatus.completed
        )
        .toList();
  }

  // Get past appointments
  List<Appointment> getPastAppointments() {
    final now = DateTime.now();
    return _appointments
        .where((a) => 
          a.appointmentDate.isBefore(now) || 
          a.status == AppointmentStatus.completed ||
          a.status == AppointmentStatus.cancelled
        )
        .toList();
  }

  Appointment? getAppointmentById(String id) {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Mechanic accepts appointment
  Future<bool> acceptAppointment(String appointmentId, {String? response}) async {
    try {
      _setLoading(true);
      _clearError();

      final updateData = {
        'status': AppointmentStatus.accepted.name,
        'mechanic_response': response,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client
          .from('appointments')
          .update(updateData)
          .eq('id', appointmentId);

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.accepted,
          mechanicResponse: response,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to accept appointment: ${e.toString()}');
      debugPrint('Error accepting appointment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mechanic declines appointment
  Future<bool> declineAppointment(String appointmentId, {String? reason}) async {
    try {
      _setLoading(true);
      _clearError();

      final updateData = {
        'status': AppointmentStatus.declined.name,
        'mechanic_response': reason,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client
          .from('appointments')
          .update(updateData)
          .eq('id', appointmentId);

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.declined,
          mechanicResponse: reason,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to decline appointment: ${e.toString()}');
      debugPrint('Error declining appointment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mechanic proposes alternative date
  Future<bool> proposeAlternativeDate(String appointmentId, DateTime proposedDate, {String? message}) async {
    try {
      _setLoading(true);
      _clearError();

      final updateData = {
        'status': AppointmentStatus.proposed.name,
        'proposed_date': proposedDate.toIso8601String(),
        'mechanic_response': message,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client
          .from('appointments')
          .update(updateData)
          .eq('id', appointmentId);

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.proposed,
          proposedDate: proposedDate,
          mechanicResponse: message,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to propose alternative date: ${e.toString()}');
      debugPrint('Error proposing date: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Client confirms proposed date
  Future<bool> confirmProposedDate(String appointmentId) async {
    try {
      _setLoading(true);
      _clearError();

      final appointment = getAppointmentById(appointmentId);
      if (appointment == null || appointment.proposedDate == null) {
        _setError('No proposed date found');
        return false;
      }

      final updateData = {
        'status': AppointmentStatus.confirmed.name,
        'appointment_date': appointment.proposedDate!.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client
          .from('appointments')
          .update(updateData)
          .eq('id', appointmentId);

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.confirmed,
          appointmentDate: appointment.proposedDate,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to confirm proposed date: ${e.toString()}');
      debugPrint('Error confirming date: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel appointment (by mechanic or customer)
  Future<bool> cancelAppointment(String appointmentId, {String? reason, bool isMechanic = false}) async {
    try {
      _setLoading(true);
      _clearError();

      final appointment = getAppointmentById(appointmentId);
      if (appointment == null) {
        _setError('Appointment not found');
        return false;
      }

      // Store the reason in notes field since cancellation_reason column doesn't exist
      final updateData = {
        'status': AppointmentStatus.cancelled.name,
        'notes': reason != null && reason.isNotEmpty 
            ? 'Cancellation reason: $reason' 
            : 'Cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseService.client
          .from('appointments')
          .update(updateData)
          .eq('id', appointmentId);

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: AppointmentStatus.cancelled,
          notes: updateData['notes'] as String,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      // Note: Notification will be sent via real-time subscription to the other party
      return true;
    } catch (e) {
      _setError('Failed to cancel appointment: ${e.toString()}');
      debugPrint('Error cancelling appointment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set up real-time subscription for appointment updates
  void subscribeToAppointments(String userId, {bool asMechanic = false}) {
    _currentUserId = userId;
    _isCustomer = !asMechanic;

    // Unsubscribe from previous channel if exists
    unsubscribeFromAppointments();

    // Create a new channel for this user
    _appointmentChannel = SupabaseService.client
        .channel('appointments_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'appointments',
          filter: asMechanic
              ? PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'mechanic_id', value: userId)
              : PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'customer_id', value: userId),
          callback: (payload) {
            _handleAppointmentUpdate(payload);
          },
        )
        .subscribe();

    debugPrint('Subscribed to appointment updates for user $userId (${asMechanic ? 'mechanic' : 'customer'})');
  }

  // Handle appointment update from real-time subscription
  void _handleAppointmentUpdate(PostgresChangePayload payload) {
    try {
      final updatedData = payload.newRecord;

      final appointmentId = updatedData['id'] as String;
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      
      if (index == -1) return;

      final oldAppointment = _appointments[index];
      final newStatus = AppointmentStatus.values.firstWhere(
        (s) => s.name == updatedData['status'],
        orElse: () => AppointmentStatus.pending,
      );

      // Only show notifications for customers
      if (_isCustomer && oldAppointment.status != newStatus) {
        _showNotificationForStatusChange(newStatus, oldAppointment, updatedData);
      }

      // Reload appointments to get updated data with relations
      if (_currentUserId != null) {
        loadAppointments(_currentUserId!, asMechanic: !_isCustomer);
      }
    } catch (e) {
      debugPrint('Error handling appointment update: $e');
    }
  }

  // Show notification based on status change
  void _showNotificationForStatusChange(
    AppointmentStatus newStatus,
    Appointment oldAppointment,
    Map<String, dynamic> updatedData,
  ) {
    final notificationService = NotificationService();

    switch (newStatus) {
      case AppointmentStatus.accepted:
        notificationService.showAppointmentAcceptedNotification('Your mechanic');
        break;
      case AppointmentStatus.declined:
        final reason = updatedData['mechanic_response'] as String?;
        notificationService.showAppointmentDeclinedNotification('Your mechanic', reason);
        break;
      case AppointmentStatus.proposed:
        final proposedDateStr = updatedData['proposed_date'] as String?;
        if (proposedDateStr != null) {
          final proposedDate = DateTime.parse(proposedDateStr);
          notificationService.showAlternativeDateProposedNotification('Your mechanic', proposedDate);
        }
        break;
      case AppointmentStatus.confirmed:
        notificationService.showAppointmentConfirmedNotification();
        break;
      case AppointmentStatus.completed:
        notificationService.showAppointmentCompletedNotification();
        break;
      case AppointmentStatus.cancelled:
        // Extract reason from notes field
        final notes = updatedData['notes'] as String?;
        String? reason;
        if (notes != null && notes.startsWith('Cancellation reason: ')) {
          reason = notes.replaceFirst('Cancellation reason: ', '');
        }
        // Determine who cancelled based on who the current user is
        final cancelledBy = _isCustomer ? 'Your mechanic' : 'The customer';
        notificationService.showAppointmentCancelledNotification(cancelledBy, reason);
        break;
      default:
        break;
    }
  }

  // Unsubscribe from real-time updates
  void unsubscribeFromAppointments() {
    if (_appointmentChannel != null) {
      SupabaseService.client.removeChannel(_appointmentChannel!);
      _appointmentChannel = null;
      debugPrint('Unsubscribed from appointment updates');
    }
  }

  @override
  void dispose() {
    unsubscribeFromAppointments();
    super.dispose();
  }
}
