import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app_shell.dart';
import 'auth_screen.dart';
import 'auth_service.dart';
import 'api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // Use MultiProvider for multiple providers
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthService(),
        ),
        Provider<ApiService>( // Provide ApiService
          create: (context) => ApiService(
            Provider.of<AuthService>(context, listen: false), // Pass AuthService
          ),
        ),
      ],
      child: MaterialApp(
        title: 'フラッシュカードアプリ',
        theme: _buildTheme(context),
        home: const AuthWrapper(),
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    final textTheme = GoogleFonts.notoSansJpTextTheme(Theme.of(context).textTheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00BCD4),
        brightness: Brightness.light,
        primary: const Color(0xFF00BCD4),
        secondary: const Color(0xFFFFC107),
        error: const Color(0xFFF44336),
      ),
      textTheme: textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        shadowColor: Colors.grey.withOpacity(0.2),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF00BCD4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF00BCD4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: authService.isAuthenticated
          ? const AppShell()
          : const AuthScreen(),
    );
  }
}
