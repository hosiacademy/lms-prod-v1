// lib/src/core/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../api/api_client.dart';

/// Theme service for managing app theme (light/dark mode)
/// Integrates with Django backend for theme persistence
class ThemeService extends ChangeNotifier {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyBackendSync = 'theme_backend_synced';

  ThemeMode _themeMode = ThemeMode.dark; // Dark mode as default
  bool _isBackendSynced = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isBackendSynced => _isBackendSynced;

  /// Initialize theme from local storage and backend
  Future<void> initialize() async {
    print('🎨 ThemeService: Initializing...');
    final prefs = await SharedPreferences.getInstance();

    // Load from local storage
    final savedThemeIndex = prefs.getInt(_keyThemeMode);
    if (savedThemeIndex != null) {
      _themeMode = ThemeMode.values[savedThemeIndex];
      print('🎨 ThemeService: Loaded from local: ${_themeMode.name}');
    }

    _isBackendSynced = prefs.getBool(_keyBackendSync) ?? false;

    // Fetch theme from Django backend if user is authenticated
    if (await AuthService.isAuthenticated()) {
      await _fetchThemeFromBackend();
    } else {
      print('ℹ️ ThemeService: Unauthenticated, skipping backend fetch');
    }

    notifyListeners();
    print('🎨 ThemeService: Initialized with mode: ${_themeMode.name}');
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    print('🎨 ThemeService: Toggling theme...');
    final newMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  /// Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    print('🎨 ThemeService: Setting theme to ${mode.name}');
    _themeMode = mode;

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);

    // Sync with Django backend
    await _syncThemeToBackend(mode);

    notifyListeners();
    print('✅ ThemeService: Theme updated to ${mode.name}');
  }

  /// Set theme based on system setting
  Future<void> setSystemTheme() async {
    print('🎨 ThemeService: Setting system theme');
    await setThemeMode(ThemeMode.system);
  }

  /// Sync theme preference to Django backend
  Future<void> _syncThemeToBackend(ThemeMode mode) async {
    try {
      // Check if user is authenticated before syncing
      if (!await AuthService.isAuthenticated()) {
        print('ℹ️ ThemeService: Unauthenticated, skipping backend sync');
        return;
      }

      print('🔄 ThemeService: Syncing to backend...');

      // Sync with Django backend API
      final response = await ApiClient.post(
        '/api/v1/user/theme/',
        data: {'theme_mode': mode.name},
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyBackendSync, true);
        _isBackendSynced = true;
        print('✅ ThemeService: Synced to backend (mode: ${mode.name})');
      } else {
        throw Exception('Backend returned status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ThemeService: Backend sync failed: $e');
      _isBackendSynced = false;
      // Still save locally even if backend sync fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBackendSync, false);
    }
  }

  /// Fetch theme preference from Django backend
  Future<void> _fetchThemeFromBackend() async {
    try {
      print('📥 ThemeService: Fetching from backend...');

      final response = await ApiClient.get('/api/v1/user/theme/');
      if (response.statusCode == 200) {
        final themeName = response.data['theme_mode'] as String?;
        if (themeName != null) {
          final themeMode = ThemeMode.values.firstWhere(
            (mode) => mode.name == themeName,
            orElse: () => ThemeMode.dark,
          );
          _themeMode = themeMode;
          _isBackendSynced = true;

          // Save to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_keyThemeMode, themeMode.index);
          await prefs.setBool(_keyBackendSync, true);

          print('✅ ThemeService: Fetched from backend: ${themeMode.name}');
        }
      }
    } catch (e) {
      print('❌ ThemeService: Backend fetch failed: $e');
      // Continue with local theme if backend fetch fails
    }
  }

  /// Force sync with backend (useful after login)
  Future<void> syncWithBackend() async {
    print('🔄 ThemeService: Force syncing with backend...');
    await _fetchThemeFromBackend();
    if (_themeMode != ThemeMode.system) {
      await _syncThemeToBackend(_themeMode);
    }
    notifyListeners();
  }

  /// Reset theme to default (dark mode)
  Future<void> reset() async {
    print('🔄 ThemeService: Resetting to default');
    await setThemeMode(ThemeMode.dark); // Reset to dark mode
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBackendSync, false);
    _isBackendSynced = false;
  }
}
