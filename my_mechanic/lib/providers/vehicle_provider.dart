import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/vehicle.dart';
import '../services/supabase_service.dart';

// Result class for addVehicle operation
class AddVehicleResult {
  final bool success;
  final bool wasLinked; // true if vehicle was linked, false if newly created
  final String? error;

  AddVehicleResult({
    required this.success,
    this.wasLinked = false,
    this.error,
  });
}

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

      // Load vehicles through the vehicle_access junction table
      final response = await SupabaseService.client
          .from('vehicle_access')
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

  Future<AddVehicleResult> addVehicle(Vehicle vehicle, String userId) async {
    try {
      _setLoading(true);
      _clearError();

      debugPrint('=== ADD VEHICLE FLOW STARTED ===');
      debugPrint('User ID: $userId');
      debugPrint('VIN: ${vehicle.vin}');
      debugPrint('VIN length: ${vehicle.vin.length}');
      debugPrint('VIN trimmed: "${vehicle.vin.trim()}"');
      debugPrint('Checking for existing vehicle with VIN: ${vehicle.vin}');
      
      // First, check if a vehicle with this VIN already exists
      final existingVehicle = await SupabaseService.client
          .from('vehicles')
          .select()
          .eq('vin', vehicle.vin)
          .maybeSingle();
      
      debugPrint('Query result: ${existingVehicle != null ? "FOUND existing vehicle" : "NO existing vehicle"}');
      if (existingVehicle != null) {
        debugPrint('Existing vehicle data: $existingVehicle');
      }

      if (existingVehicle != null) {
        debugPrint('Found existing vehicle with VIN: ${vehicle.vin}, ID: ${existingVehicle['id']}');
        
        // Vehicle exists, check if user is already linked
        final existingLink = await SupabaseService.client
            .from('vehicle_access')
            .select()
            .eq('user_id', userId)
            .eq('vehicle_id', existingVehicle['id'])
            .maybeSingle();

        if (existingLink != null) {
          debugPrint('User already has access to this vehicle in database');
          
          // Check if vehicle is in local list
          final isInLocalList = _vehicles.any((v) => v.id == existingVehicle['id']);
          debugPrint('Vehicle in local list: $isInLocalList');
          
          if (!isInLocalList) {
            debugPrint('Vehicle not in local list, adding it now (sync issue fix)');
            final linkedVehicle = Vehicle.fromJson(existingVehicle);
            _vehicles.insert(0, linkedVehicle);
            notifyListeners();
            return AddVehicleResult(success: true, wasLinked: true);
          }
          
          debugPrint('Vehicle already in local list - true duplicate');
          _setError('You already have access to this vehicle.');
          return AddVehicleResult(success: false, error: 'You already have access to this vehicle.');
        }

        debugPrint('Linking user to existing vehicle');
        // Link user to existing vehicle
        try {
          await SupabaseService.client
              .from('vehicle_access')
              .insert({
                'user_id': userId,
                'vehicle_id': existingVehicle['id'],
                'access_level': 'edit',
                'granted_by': userId,
              });
        } on PostgrestException catch (e) {
          if (e.code == '23505' && e.message.contains('vehicle_access_vehicle_id_user_id_key')) {
            // Link already exists (race condition), just add to local list
            debugPrint('Link already exists in database (race condition), adding to local list');
            final linkedVehicle = Vehicle.fromJson(existingVehicle);
            if (!_vehicles.any((v) => v.id == existingVehicle['id'])) {
              _vehicles.insert(0, linkedVehicle);
              notifyListeners();
            }
            return AddVehicleResult(success: true, wasLinked: true);
          }
          rethrow;
        }

        // Load the vehicle into the list
        final linkedVehicle = Vehicle.fromJson(existingVehicle);
        _vehicles.insert(0, linkedVehicle);
        notifyListeners();
        
        debugPrint('Successfully linked to existing vehicle');
        return AddVehicleResult(success: true, wasLinked: true);
      }

      debugPrint('No existing vehicle found, creating new vehicle with VIN: ${vehicle.vin}');
      // Vehicle doesn't exist, create new one
      final vehicleData = vehicle.copyWith(ownerId: userId);
      
      debugPrint('Adding new vehicle: ${vehicleData.toJson(excludeId: true)}');
      
      final response = await SupabaseService.client
          .from('vehicles')
          .insert(vehicleData.toJson(excludeId: true))
          .select()
          .single();

      final newVehicle = Vehicle.fromJson(response);
      
      debugPrint('Vehicle created successfully with ID: ${newVehicle.id}');
      
      // Link will be created automatically by database trigger
      // Verify the link was created
      final linkCheck = await SupabaseService.client
          .from('vehicle_access')
          .select()
          .eq('user_id', userId)
          .eq('vehicle_id', newVehicle.id!)
          .maybeSingle();
      
      if (linkCheck == null) {
        debugPrint('WARNING: Trigger did not create vehicle_access link, creating manually');
        try {
          await SupabaseService.client
              .from('vehicle_access')
              .insert({
                'user_id': userId,
                'vehicle_id': newVehicle.id!,
                'access_level': 'owner',
                'granted_by': userId,
              });
        } on PostgrestException catch (e) {
          if (e.code == '23505' && e.message.contains('vehicle_access_vehicle_id_user_id_key')) {
            debugPrint('Link already exists (created by trigger or race condition), continuing...');
          } else {
            rethrow;
          }
        }
      } else {
        debugPrint('Trigger successfully created vehicle_access link');
      }
      
      // Add to our local list if not already there
      if (!_vehicles.any((v) => v.id == newVehicle.id)) {
        _vehicles.insert(0, newVehicle);
        notifyListeners();
      }
      return AddVehicleResult(success: true);
    } on PostgrestException catch (e) {
      // Handle PostgreSQL errors
      String errorMessage;
      if (e.code == '23505') {
        // Check if it's a VIN conflict or vehicle_access conflict
        if (e.message.contains('vehicle_access_vehicle_id_user_id_key')) {
          // This means user is already linked to the vehicle
          errorMessage = 'You already have access to this vehicle.';
        } else if (e.message.contains('vehicles_vin_key')) {
          // This is a VIN conflict
          errorMessage = 'This VIN already exists. Please check the VIN number.';
        } else {
          // Generic duplicate key error
          errorMessage = 'This vehicle already exists in the system.';
        }
      } else {
        errorMessage = 'Database error: ${e.message}';
      }
      _setError(errorMessage);
      debugPrint('PostgreSQL error adding vehicle: ${e.code} - ${e.message}');
      debugPrint('Full error details: ${e.details}');
      return AddVehicleResult(success: false, error: errorMessage);
    } catch (e) {
      final errorMessage = 'Failed to add vehicle: ${e.toString()}';
      _setError(errorMessage);
      debugPrint('Error adding vehicle: $e');
      return AddVehicleResult(success: false, error: errorMessage);
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
          .from('vehicle_access')
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
            .from('vehicle_access')
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
          .from('vehicle_access')
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
          .from('vehicle_access')
          .select('user_id, access_level, users(first_name, last_name, email)')
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

  void clearVehicleData() {
    _vehicles.clear();
    _clearError();
    notifyListeners();
  }

  // Upload vehicle image to Supabase storage and update vehicle record
  Future<bool> uploadVehicleImage(String vehicleId, String imagePath) async {
    try {
      _setLoading(true);
      _clearError();

      final vehicle = getVehicleById(vehicleId);
      if (vehicle == null) {
        _setError('Vehicle not found');
        return false;
      }

      // Delete old image if exists
      if (vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty) {
        try {
          final oldImagePath = _extractPathFromUrl(vehicle.imageUrl!);
          if (oldImagePath != null) {
            await SupabaseService.client.storage
                .from('vehicle-images')
                .remove([oldImagePath]);
          }
        } catch (e) {
          debugPrint('Error deleting old image: $e');
          // Continue even if deletion fails
        }
      }

      // Upload new image
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final fileExt = imagePath.split('.').last;
      final fileName = '$vehicleId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await SupabaseService.client.storage
          .from('vehicle-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              upsert: true,
            ),
          );

      // Get public URL
      final imageUrl = SupabaseService.client.storage
          .from('vehicle-images')
          .getPublicUrl(filePath);

      // Update vehicle record with new image URL
      await SupabaseService.client
          .from('vehicles')
          .update({'image_url': imageUrl, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', vehicleId);

      // Update local vehicle
      final index = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (index != -1) {
        _vehicles[index] = vehicle.copyWith(
          imageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to upload image: ${e.toString()}');
      debugPrint('Error uploading vehicle image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove vehicle image
  Future<bool> removeVehicleImage(String vehicleId) async {
    try {
      _setLoading(true);
      _clearError();

      final vehicle = getVehicleById(vehicleId);
      if (vehicle == null) {
        _setError('Vehicle not found');
        return false;
      }

      // Delete image from storage if exists
      if (vehicle.imageUrl != null && vehicle.imageUrl!.isNotEmpty) {
        try {
          final imagePath = _extractPathFromUrl(vehicle.imageUrl!);
          if (imagePath != null) {
            await SupabaseService.client.storage
                .from('vehicle-images')
                .remove([imagePath]);
          }
        } catch (e) {
          debugPrint('Error deleting image from storage: $e');
          // Continue even if deletion fails
        }
      }

      // Update vehicle record to remove image URL
      await SupabaseService.client
          .from('vehicles')
          .update({'image_url': null, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', vehicleId);

      // Update local vehicle
      final index = _vehicles.indexWhere((v) => v.id == vehicleId);
      if (index != -1) {
        _vehicles[index] = vehicle.copyWith(
          imageUrl: null,
          clearImageUrl: true,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to remove image: ${e.toString()}');
      debugPrint('Error removing vehicle image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to extract file path from Supabase storage URL
  String? _extractPathFromUrl(String url) {
    try {
      // URL format: https://<project>.supabase.co/storage/v1/object/public/vehicle-images/<filename>
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('vehicle-images');
      if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
        return segments.sublist(bucketIndex + 1).join('/');
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting path from URL: $e');
      return null;
    }
  }
}
