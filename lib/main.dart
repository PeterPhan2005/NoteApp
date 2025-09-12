import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:testproject/screens/splash.dart';
import 'package:testproject/services/theme_service.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack Trace: ${details.stack}');
  };

  // Set up error handling for async operations
  runZonedGuarded(() async {
    await Firebase.initializeApp();
    runApp(const MyApp());
  }, (error, stackTrace) {
    print('Zone Error: $error');
    print('Stack Trace: $stackTrace');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();
  ThemeData _currentTheme = ThemeService().lightTheme;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    await _themeService.loadThemePreferences();
    setState(() {
      _currentTheme = _themeService.currentTheme;
    });
    
    // Listen for theme changes
    _themeService.onThemeChanged = (theme) {
      setState(() {
        _currentTheme = theme;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _currentTheme,
      home: const SplashScreen(),
    );
  }
}
