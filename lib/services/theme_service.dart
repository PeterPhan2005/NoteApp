import 'package:flutter/material.dart';
import 'package:testproject/services/user_service.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  final UserService _userService = UserService();
  
  // Callback to notify when theme changes
  Function(ThemeData)? onThemeChanged;
  
  bool _isDarkTheme = false;
  bool get isDarkTheme => _isDarkTheme;

  // Light Theme
  final ThemeData lightTheme = ThemeData(
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
  );

  // Dark Theme
  final ThemeData darkTheme = ThemeData(
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
    scaffoldBackgroundColor: Colors.grey[900],
  );

  ThemeData get currentTheme => _isDarkTheme ? darkTheme : lightTheme;

  // Load theme preferences
  Future<void> loadThemePreferences() async {
    try {
      final userProfile = await _userService.getUserProfile();
      if (userProfile != null) {
        _isDarkTheme = userProfile.preferences['theme'] == 'dark';
      }
    } catch (e) {
      print('Error loading theme preferences: $e');
    }
  }

  // Set theme
  Future<void> setTheme(bool isDark) async {
    if (_isDarkTheme != isDark) {
      _isDarkTheme = isDark;
      
      // Save to database
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

      // Notify listeners
      onThemeChanged?.call(currentTheme);
    }
  }
}
