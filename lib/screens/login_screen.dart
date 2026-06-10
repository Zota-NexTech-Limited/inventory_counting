// Login screen — used when live API mode is on. Authenticates via /auth/login.
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/auth_repository.dart';
import '../theme/tokens.dart';
import '../widgets/primitives.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthRepository.instance.login(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not sign in. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.rLg),
                  child: const Icon(AppIcons.item, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                Text('Inventory Counting', textAlign: TextAlign.center, style: AppText.sans(size: 20, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Sign in to continue', textAlign: TextAlign.center, style: AppText.sans(size: 12, color: AppColors.ink3)),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Field(
                        label: 'Email',
                        required: true,
                        child: TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: AppText.sans(size: 13),
                          decoration: appInputDecoration(hintText: 'you@company.com'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Field(
                        label: 'Password',
                        required: true,
                        child: TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          onSubmitted: (_) => _login(),
                          style: AppText.sans(size: 13),
                          decoration: appInputDecoration(hintText: '••••••••').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? AppIcons.visibility : AppIcons.visibilityOff, size: 18, color: AppColors.ink3),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.redBg, borderRadius: AppRadius.rMd, border: Border.all(color: AppColors.redBorder)),
                          child: Row(
                            children: [
                              const Icon(AppIcons.error, size: 15, color: AppColors.redFg),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: AppText.sans(size: 11.5, color: AppColors.redFg))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppButton(
                        block: true,
                        label: _busy ? 'Signing in…' : 'Sign In',
                        icon: _busy ? null : AppIcons.login,
                        enabled: !_busy,
                        onTap: _login,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
