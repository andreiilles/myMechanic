import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/app_user.dart';
import '../models/mechanic.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider with ChangeNotifier {
  AppUser? _currentUser;
  Mechanic? _mechanicProfile;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  Mechanic? get mechanicProfile => _mechanicProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isMechanic => _currentUser?.userType == UserType.mechanic;

  Future<bool> createUserProfile(AppUser user) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await SupabaseService.client
          .from('users')
          .insert(user.toJson(excludeId: true))
          .select()
          .single();

      _currentUser = AppUser.fromJson(response);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create user profile: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createMechanicProfile(Mechanic mechanic) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await SupabaseService.client
          .from('mechanic_profiles')
          .insert(mechanic.toJson(excludeId: true))
          .select()
          .single();

      _mechanicProfile = Mechanic.fromJson(response);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create mechanic profile: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserProfile(String authId) async {
    try {
      _setLoading(true);
      _clearError();

      // Load user profile
      final userResponse = await SupabaseService.client
          .from('users')
          .select()
          .eq('auth_id', authId)
          .single();

      _currentUser = AppUser.fromJson(userResponse);

      // If user is a mechanic, load mechanic profile
      if (_currentUser!.userType == UserType.mechanic) {
        try {
          final mechanicResponse = await SupabaseService.client
              .from('mechanic_profiles')
              .select()
              .eq('user_id', _currentUser!.id!)
              .single();

          _mechanicProfile = Mechanic.fromJson(mechanicResponse);
        } catch (e) {
          // Mechanic profile might not exist yet
          debugPrint('Mechanic profile not found: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to load user profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserProfile(AppUser user) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await SupabaseService.client
          .from('users')
          .update(updatedUser.toJson(excludeId: true))
          .eq('id', user.id!);

      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update user profile: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMechanicProfile(Mechanic mechanic) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedMechanic = mechanic.copyWith(updatedAt: DateTime.now());
      await SupabaseService.client
          .from('mechanic_profiles')
          .update(updatedMechanic.toJson(excludeId: true))
          .eq('id', mechanic.id!);

      _mechanicProfile = updatedMechanic;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update mechanic profile: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Mechanic>> loadAllMechanics() async {
    try {
      final response = await SupabaseService.client
          .from('mechanic_profiles')
          .select()
          .order('average_rating', ascending: false);

      final mechanics = (response as List)
          .map((json) => Mechanic.fromJson(json))
          .toList();

      return mechanics;
    } catch (e) {
      debugPrint('Error loading mechanics: $e');
      return [];
    }
  }

  // Upload profile image to Supabase storage and update user record
  Future<bool> uploadProfileImage(String imagePath) async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null) {
        _setError('No user logged in');
        return false;
      }

      // Delete old image if exists
      if (_currentUser!.profileImageUrl != null && 
          _currentUser!.profileImageUrl!.isNotEmpty) {
        try {
          final oldImagePath = _extractPathFromUrl(_currentUser!.profileImageUrl!);
          if (oldImagePath != null) {
            await SupabaseService.client.storage
                .from('profile-images')
                .remove([oldImagePath]);
          }
        } catch (e) {
          debugPrint('Error deleting old profile image: $e');
          // Continue even if deletion fails
        }
      }

      // Upload new image
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final fileExt = imagePath.split('.').last;
      final fileName = '${_currentUser!.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await SupabaseService.client.storage
          .from('profile-images')
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
          .from('profile-images')
          .getPublicUrl(filePath);

      // Update user record with new image URL
      await SupabaseService.client
          .from('users')
          .update({
            'profile_image_url': imageUrl, 
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', _currentUser!.id!);

      // Update local user
      _currentUser = _currentUser!.copyWith(
        profileImageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to upload profile image: ${e.toString()}');
      debugPrint('Error uploading profile image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove profile image
  Future<bool> removeProfileImage() async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null) {
        _setError('No user logged in');
        return false;
      }

      if (_currentUser!.profileImageUrl == null || 
          _currentUser!.profileImageUrl!.isEmpty) {
        return true; // Nothing to remove
      }

      // Delete image from storage
      try {
        final imagePath = _extractPathFromUrl(_currentUser!.profileImageUrl!);
        if (imagePath != null) {
          await SupabaseService.client.storage
              .from('profile-images')
              .remove([imagePath]);
        }
      } catch (e) {
        debugPrint('Error deleting profile image from storage: $e');
        // Continue even if deletion fails
      }

      // Update user record to remove image URL
      await SupabaseService.client
          .from('users')
          .update({
            'profile_image_url': null, 
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', _currentUser!.id!);

      // Update local user
      _currentUser = _currentUser!.copyWith(
        profileImageUrl: null,
        updatedAt: DateTime.now(),
      );
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to remove profile image: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Extract file path from Supabase public URL
  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length >= 3) {
        // URL format: .../storage/v1/object/public/bucket-name/file-name
        return segments.skip(segments.length - 1).join('/');
      }
    } catch (e) {
      debugPrint('Error extracting path from URL: $e');
    }
    return null;
  }

  void clearUserData() {
    _currentUser = null;
    _mechanicProfile = null;
    _clearError();
    notifyListeners();
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
