import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum AuthState { unknown, unauthenticated, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.unknown;
  Map<String, dynamic>? _user;
  String? _error;
  bool _loading = false;

  AuthState get state   => _state;
  Map<String, dynamic>? get user => _user;
  String? get error     => _error;
  bool get loading      => _loading;
  bool get isAuth       => _state == AuthState.authenticated;

  // ── Init (called on app start) ────────────────────────────────────────────

  Future<void> init() async {
    await ApiService.loadTokens();
    if (ApiService.isLoggedIn) {
      try {
        _user  = await ApiService.getMe();
        _state = AuthState.authenticated;
      } catch (_) {
        await ApiService.clearTokens();
        _state = AuthState.unauthenticated;
      }
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _user  = await ApiService.register(name: name, username: username, email: email, password: password);
      _state = AuthState.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      _user  = await ApiService.login(email: email, password: password);
      _state = AuthState.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await ApiService.logout();
    _user  = null;
    _state = AuthState.unauthenticated;
    _error = null;
    notifyListeners();
  }

  // ── Update user locally after profile edit ────────────────────────────────

  void updateUser(Map<String, dynamic> updated) {
    _user = {...?_user, ...updated};
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
