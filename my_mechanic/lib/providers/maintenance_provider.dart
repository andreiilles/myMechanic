import 'package:flutter/foundation.dart';
import '../models/maintenance_record.dart';
import '../services/supabase_service.dart';

class MaintenanceProvider with ChangeNotifier {
  List<MaintenanceRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  List<MaintenanceRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get records for a specific vehicle
  List<MaintenanceRecord> getRecordsForVehicle(String vehicleId) {
    return _records.where((record) => record.vehicleId == vehicleId).toList()
      ..sort((a, b) => b.serviceDate.compareTo(a.serviceDate)); // Most recent first
  }

  Future<void> loadRecords(String vehicleId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await SupabaseService.client
          .from('maintenance_records')
          .select()
          .eq('vehicle_id', vehicleId)
          .order('service_date', ascending: false);

      _records = (response as List)
          .map((json) => MaintenanceRecord.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load maintenance records: ${e.toString()}');
      debugPrint('Error loading maintenance records: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addRecord(MaintenanceRecord record) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await SupabaseService.client
          .from('maintenance_records')
          .insert(record.toJson(excludeId: true))
          .select()
          .single();

      final newRecord = MaintenanceRecord.fromJson(response);
      _records.add(newRecord);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add maintenance record: ${e.toString()}');
      debugPrint('Error adding maintenance record: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRecord(MaintenanceRecord record) async {
    if (record.id == null) return false;

    try {
      _setLoading(true);
      _clearError();

      await SupabaseService.client
          .from('maintenance_records')
          .update(record.toJson())
          .eq('id', record.id!);

      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update maintenance record: ${e.toString()}');
      debugPrint('Error updating maintenance record: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRecord(String recordId) async {
    try {
      _setLoading(true);
      _clearError();

      await SupabaseService.client
          .from('maintenance_records')
          .delete()
          .eq('id', recordId);

      _records.removeWhere((record) => record.id == recordId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete maintenance record: ${e.toString()}');
      debugPrint('Error deleting maintenance record: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Calculate total maintenance cost for a vehicle
  double getTotalCostForVehicle(String vehicleId) {
    return getRecordsForVehicle(vehicleId)
        .fold(0.0, (sum, record) => sum + record.cost);
  }

  // Get upcoming maintenance (placeholder for future implementation)
  int getUpcomingMaintenanceCount(String vehicleId) {
    // TODO: Implement logic based on service intervals
    return 0;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void clearMaintenanceData() {
    _records = [];
    _clearError();
    notifyListeners();
  }
}
