import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

      // Load vehicles through the user_vehicles junction table
      final response = await SupabaseService.client
          .from('user_vehicles')
          .select('vehicle_id')
          .eq('user_id', userId);

      final vehicleIds = (response as List)
          .map((row) => row['vehicle_id'] as String)
          .toList();

      if (vehicleIds.isEmpty) {
        _vehicles = [];
        notifyListeners();
        return;
      }

      final vehiclesResponse = await SupabaseService.client
          .from('vehicles')
          .select()
          .inFilter('id', vehicleIds)
          .order('created_at', ascending: false);

      _vehicles = (vehiclesResponse as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Failed to load vehicles: ${e.toString()}');
      debugPrint('Error loading vehicles: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addVehicle(Vehicle vehicle, String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // First, check if a vehicle with this VIN already exists
      final existingVehicle = await SupabaseService.client
          .from('vehicles')
          .select()
          .eq('vin', vehicle.vin)
          .maybeSingle();

      if (existingVehicle != null) {
        // Vehicle exists, check if user is already linked
        final existingLink = await SupabaseService.client
            .from('user_vehicles')
            .select()
            .eq('user_id', userId)
            .eq('vehicle_id', existingVehicle['id'])
            .maybeSingle();

        if (existingLink != null) {
          _setError('You already have access to this vehicle.');
          return false;
        }

        // Link user to existing vehicle
        await SupabaseService.client
            .from('user_vehicles')
            .insert({
              'user_id': userId,
              'vehicle_id': existingVehicle['id'],
              'relationship': 'family_member',
            });

        // Load the vehicle into the list
        final linkedVehicle = Vehicle.fromJson(existingVehicle);
        _vehicles.insert(0, linkedVehicle);
        notifyListeners();
        
        _setError('Vehicle linked successfully! This vehicle is shared with other users.');
        return true;
      }

      // Vehicle doesn't exist, create new one
      final vehicleData = vehicle.copyWith(userId: userId);
      
      debugPrint('Adding new vehicle: ${vehicleData.toJson(excludeId: true)}');
      
      final response = await SupabaseService.client
          .from('vehicles')
          .insert(vehicleData.toJson(excludeId: true))
          .select()
          .single();

      final newVehicle = Vehicle.fromJson(response);
      
      // Link will be created automatically by database trigger
      // But we'll add to our local list
      _vehicles.insert(0, newVehicle);
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      // Handle PostgreSQL errors
      if (e.code == '23505') {
        // This shouldn't happen now since we check first, but keep as fallback
        _setError('This VIN already exists. Please check the VIN number.');
      } else {
        _setError('Database error: ${e.message}');
      }
      debugPrint('PostgreSQL error adding vehicle: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _setError('Failed to add vehicle: ${e.toString()}');
      debugPrint('Error adding vehicle: $e');
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
          .update(updatedVehicle.toJson(excludeId: true))
          .eq('id', vehicle.id!);

      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = updatedVehicle;
        notifyListeners();
      }
      return true;
    } on PostgrestException catch (e) {
      // Handle PostgreSQL errors
      if (e.code == '23505') {
        // Unique constraint violation - duplicate VIN
        _setError('This VIN already exists in the database. Please use a different VIN number.');
      } else {
        _setError('Database error: ${e.message}');
      }
      debugPrint('PostgreSQL error updating vehicle: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _setError('Failed to update vehicle: ${e.toString()}');
      debugPrint('Error updating vehicle: $e');
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
      debugPrint('Error deleting vehicle: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove user's access to a shared vehicle (unlink)
  Future<bool> unlinkVehicle(String vehicleId, String userId) async {
    try {
      _setLoading(true);
      _clearError();

      // Check how many users are linked to this vehicle
      final userLinks = await SupabaseService.client
          .from('user_vehicles')
          .select()
          .eq('vehicle_id', vehicleId);

      if ((userLinks as List).length == 1) {
        // Last user - delete the vehicle entirely
        await SupabaseService.client
            .from('vehicles')
            .delete()
            .eq('id', vehicleId);
      } else {
        // Multiple users - just remove this user's link
        await SupabaseService.client
            .from('user_vehicles')
            .delete()
            .eq('user_id', userId)
            .eq('vehicle_id', vehicleId);
      }

      _vehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to remove vehicle: ${e.toString()}');
      debugPrint('Error unlinking vehicle: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if vehicle is shared with other users
  Future<bool> isVehicleShared(String vehicleId) async {
    try {
      final userLinks = await SupabaseService.client
          .from('user_vehicles')
          .select()
          .eq('vehicle_id', vehicleId);

      return (userLinks as List).length > 1;
    } catch (e) {
      debugPrint('Error checking if vehicle is shared: $e');
      return false;
    }
  }

  // Get users who have access to a vehicle
  Future<List<Map<String, dynamic>>> getVehicleUsers(String vehicleId) async {
    try {
      final response = await SupabaseService.client
          .from('user_vehicles')
          .select('user_id, relationship, users(first_name, last_name, email)')
          .eq('vehicle_id', vehicleId);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting vehicle users: $e');
      return [];
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
