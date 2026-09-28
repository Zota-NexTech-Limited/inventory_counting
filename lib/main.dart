// Inventory Counting — Mobile ERP module.
// Recreated in Flutter from the Claude Design handoff, wired to the
// Warehouse Inventory API (see Inventory_API.pdf / AppConfig).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api/token_store.dart';
import 'theme/tokens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  await TokenStore.instance.load();
  runApp(const InventoryCountingApp());
}

class InventoryCountingApp extends StatelessWidget {
  const InventoryCountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Start at login unless a saved session exists. From login the user signs
    // in via /auth/login, or (while the backend is being deployed) continues
    // with sample data.
    final Widget home =
        TokenStore.instance.isLoggedIn ? const DashboardScreen() : const LoginScreen();
    return MaterialApp(
      title: 'Inventory Counting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.card,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: home,
    );
  }
}
