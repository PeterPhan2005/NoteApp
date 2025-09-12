import 'package:flutter/material.dart';
import 'package:testproject/services/user_service.dart';

class ThemeProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  bool _isDarkTheme = false;
  bool _autoSave = true;
  bool _notifications = true;

  bool get isDarkTheme => _isDarkTheme;
  bool get autoSave => _autoSave;
  bool get notifications => _notifications;

  ThemeData get currentTheme {
    return _isDarkTheme ? _darkTheme : _lightTheme;
  }

  // Light Theme
  final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  // Dark Theme
  final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      color: Colors.grey[800],
    ),
    scaffoldBackgroundColor: Colors.grey[900],
  );

  // Load theme preferences from user profile
  Future<void> loadThemePreferences() async {
    try {
      final userProfile = await _userService.getUserProfile();
      if (userProfile != null) {
        final preferences = userProfile.preferences;
        _isDarkTheme = preferences['theme'] == 'dark';
        _autoSave = preferences['autoSave'] ?? true;
        _notifications = preferences['notifications'] ?? true;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading theme preferences: $e');
    }
  }

  // Toggle theme
  Future<void> toggleTheme() async {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
    await _saveThemePreference();
  }

  // Set theme
  Future<void> setTheme(bool isDark) async {
    if (_isDarkTheme != isDark) {
      _isDarkTheme = isDark;
      notifyListeners();
      await _saveThemePreference();
    }
  }

  // Toggle auto save
  Future<void> toggleAutoSave() async {
    _autoSave = !_autoSave;
    notifyListeners();
    await _savePreferences();
  }

  // Toggle notifications
  Future<void> toggleNotifications() async {
    _notifications = !_notifications;
    notifyListeners();
    await _savePreferences();
  }

  // Save theme preference
  Future<void> _saveThemePreference() async {
    try {
      final userProfile = await _userService.getUserProfile();
      if (userProfile != null) {
        final updatedPreferences = Map<String, dynamic>.from(userProfile.preferences);
        updatedPreferences['theme'] = _isDarkTheme ? 'dark' : 'light';
        await _userService.updatePreferences(updatedPreferences);
      }
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  // Save all preferences
  Future<void> _savePreferences() async {
    try {
      final userProfile = await _userService.getUserProfile();
      if (userProfile != null) {
        final updatedPreferences = Map<String, dynamic>.from(userProfile.preferences);
        updatedPreferences['theme'] = _isDarkTheme ? 'dark' : 'light';
        updatedPreferences['autoSave'] = _autoSave;
        updatedPreferences['notifications'] = _notifications;
        await _userService.updatePreferences(updatedPreferences);
      }
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }
}
