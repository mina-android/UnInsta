import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UnInstaApp());
}

class UnInstaApp extends StatefulWidget {
  const UnInstaApp({super.key});

  @override
  State<UnInstaApp> createState() => _UnInstaAppState();
}

class _UnInstaAppState extends State<UnInstaApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        // system -> toggle to dark or light
        final brightness = MediaQuery.platformBrightnessOf(context);
        _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
      }
    });
  }

  bool _isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return MaterialApp(
          title: 'UnInsta',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          home: HomeScreen(
            onToggleTheme: _toggleTheme,
            isDarkMode: _isDarkMode(context),
          ),
        );
      },
    );
  }
}
