import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _hasProfile = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get hasProfile => _hasProfile;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = SupabaseService.getCurrentUser();
    if (_user != null) {
      _checkUserProfile();
    }
    
    // Listen to auth state changes
    SupabaseService.authStateChanges.listen((AuthState state) {
      _user = state.session?.user;
      if (_user != null) {
        _checkUserProfile();
      } else {
        _hasProfile = false;
      }
      notifyListeners();
    });
  }

  Future<void> _checkUserProfile() async {
    if (_user == null) return;
    
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('auth_id', _user!.id)
          .maybeSingle();
      
      _hasProfile = response != null;
    } catch (e) {
      _hasProfile = false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await SupabaseService.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        notifyListeners();
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await SupabaseService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out');
    } finally {
      _setLoading(false);
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
