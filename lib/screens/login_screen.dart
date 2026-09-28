// Login screen — used when live API mode is on. Authenticates via /auth/login.
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/app_config.dart';
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
      body: Stack(
        children: [
          // Subtle brand wash behind the top of the screen.
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEAF1FF), AppColors.bg],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 36, 22, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _CompanyLogo(),
                      const SizedBox(height: 22),
                      Text('Welcome back', textAlign: TextAlign.center, style: AppText.sans(size: 23, weight: FontWeight.w700, letterSpacing: -0.46)),
                      const SizedBox(height: 4),
                      Text('Sign in to your Inventory Counting workspace', textAlign: TextAlign.center, style: AppText.sans(size: 12.5, color: AppColors.ink3)),
                      const SizedBox(height: 22),
                      AppCard(
                        padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                // While the backend is being deployed, let testers into the app
                // on sample data without a real account.
                if (!AppConfig.useLiveApi) ...[
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or', style: AppText.sans(size: 11, color: AppColors.ink4)),
                      ),
                      const Expanded(child: Divider(color: AppColors.line)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    block: true,
                    variant: BtnVariant.ghost,
                    label: 'Continue with sample data',
                    icon: AppIcons.visibility,
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Live sign-in activates once the backend APIs are deployed.',
                    textAlign: TextAlign.center,
                    style: AppText.sans(size: 10.5, color: AppColors.ink4),
                  ),
                ],
                  ],
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      );
  }
}

/// Company logo slot.
///
/// Renders the brand mark as a vector ([_NextechMark]). If you later drop a
/// `assets/images/company_logo.png` into the project it is used instead
/// (declared in pubspec) — no code change needed.
class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo();

  static const String asset = 'assets/images/company_logo.png';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 104,
        height: 104,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.rXl,
          border: Border.all(color: AppColors.line),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _NextechMark(),
        ),
      ),
    );
  }
}

/// Vector recreation of the company mark — black + orange interlocking
/// chevrons on a cream tile (rotationally symmetric about the centre).
class _NextechMark extends StatelessWidget {
  const _NextechMark();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _NextechPainter(), size: Size.infinite);
}

class _NextechPainter extends CustomPainter {
  static const Color cream = Color(0xFFF7E6DF);
  static const Color black = Color(0xFF141414);
  static const Color orange = Color(0xFFE8821E);

  @override
  void paint(Canvas canvas, Size size) {
    // Cream backdrop (matches the supplied logo background).
    canvas.drawRect(Offset.zero & size, Paint()..color = cream);

    // Work in a centred 0–100 square so the mark scales cleanly.
    final s = size.shortestSide;
    final ox = (size.width - s) / 2;
    final oy = (size.height - s) / 2;
    Offset p(double x, double y) => Offset(ox + x / 100 * s, oy + y / 100 * s);

    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.155 * s
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter
      ..strokeMiterLimit = 8;

    void draw(List<Offset> pts, Color c) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, stroke(c));
    }

    // Two-tone "N": black = left leg + upper diagonal; orange = right leg +
    // lower diagonal (180° rotation). They meet at the centre.
    draw([p(28, 84), p(28, 24), p(52, 52)], black);
    draw([p(72, 16), p(72, 76), p(48, 48)], orange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
