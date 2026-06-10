// Inventory Counting — Mobile ERP module.
// Recreated in Flutter from the Claude Design handoff, wired to the
// Warehouse Inventory API (see Inventory_API.pdf / AppConfig).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api/token_store.dart';
import 'api/app_config.dart';
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
  if (AppConfig.useLiveApi) {
    await TokenStore.instance.load();
  }
  runApp(const InventoryCountingApp());
}

class InventoryCountingApp extends StatelessWidget {
  const InventoryCountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Live mode starts at login unless we already hold a token; otherwise the
    // app runs on bundled sample data straight from the dashboard.
    final Widget home = (AppConfig.useLiveApi && !TokenStore.instance.isLoggedIn)
        ? const LoginScreen()
        : const DashboardScreen();
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
