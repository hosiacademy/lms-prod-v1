import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class User {
  final String email;
  final String? name;
  final String role;

  User({
    required this.email,
    this.name,
    required this.role,
  });
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> init() async {
    await checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final authenticated =
          await AuthService.isAuthenticated(); // Static property?
      if (authenticated) {
        final email = await AuthService.getUserEmail();
        final name = await AuthService.getUserName();
        final role = await AuthService.getUserRole();

        if (email != null && role != null) {
          _user = User(email: email, name: name, role: role);
        }
      } else {
        _user = null;
      }
    } catch (e) {
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await AuthService.login(email: email, password: password);
      if (success) {
        await checkAuthStatus();
      }
    } catch (e) {
      // Handle login error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }
}
