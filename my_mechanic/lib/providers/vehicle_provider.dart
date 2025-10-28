import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/supabase_service.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _error;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadVehicles(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await SupabaseService.client
          .from('vehicles')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _vehicles = (response as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load vehicles: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addVehicle(Vehicle vehicle, String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final vehicleData = vehicle.copyWith(userId: userId);
      final response = await SupabaseService.client
          .from('vehicles')
          .insert(vehicleData.toJson())
          .select()
          .single();

      final newVehicle = Vehicle.fromJson(response);
      _vehicles.insert(0, newVehicle);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add vehicle: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedVehicle = vehicle.copyWith(updatedAt: DateTime.now());
      await SupabaseService.client
          .from('vehicles')
          .update(updatedVehicle.toJson())
          .eq('id', vehicle.id!);

      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = updatedVehicle;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update vehicle: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      _setLoading(true);
      _clearError();

      await SupabaseService.client
          .from('vehicles')
          .delete()
          .eq('id', vehicleId);

      _vehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete vehicle: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Vehicle? getVehicleById(String id) {
    try {
      return _vehicles.firstWhere((vehicle) => vehicle.id == id);
    } catch (e) {
      return null;
    }
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
}
