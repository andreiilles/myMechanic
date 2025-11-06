import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/mechanic.dart';
import '../services/supabase_service.dart';

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
