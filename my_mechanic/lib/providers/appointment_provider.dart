import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../services/supabase_service.dart';

class AppointmentProvider with ChangeNotifier {
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;

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

      final query = SupabaseService.client
          .from('appointments')
          .select('''
            *,
            customer:users!appointments_customer_id_fkey(id, first_name, last_name, email, phone_number),
            mechanic:users!appointments_mechanic_id_fkey(id, first_name, last_name, email, phone_number),
            vehicle:vehicles(id, make, model, year, vin, license_plate)
          ''');

      final response = asMechanic
          ? await query.eq('mechanic_id', userId).order('appointment_date', ascending: true)
          : await query.eq('customer_id', userId).order('appointment_date', ascending: true);

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
            vehicle:vehicles(id, make, model, year, vin, license_plate)
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
}
