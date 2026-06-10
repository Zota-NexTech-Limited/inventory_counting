// Screens 06 / 07 · Barcode Scanner (item + rack modes).
// The detection is simulated (as in the prototype) — a mock result slides up
// after ~1.6s, with rack-match validation surfaced inline.
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/primitives.dart';

class ScanResult {
  final String type; // 'item' | 'rack'
  final String code;
  final String? name;
  final String? rackId;
  final String? zone;
  final int? bins;
  final String? expectedRack;
  const ScanResult({required this.type, required this.code, this.name, this.rackId, this.zone, this.bins, this.expectedRack});
}

/// Pushes the full-screen scanner. Returns a [ScanResult] when the user
/// accepts a detection, or null if cancelled.
Future<ScanResult?> openScanner(BuildContext context, {required String mode, required String currentRack}) {
  return Navigator.of(context).push<ScanResult>(PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => BarcodeScanner(mode: mode, currentRack: currentRack),
    transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
  ));
}

class BarcodeScanner extends StatefulWidget {
  final String mode;
  final String currentRack;
  const BarcodeScanner({super.key, required this.mode, required this.currentRack});

  @override
  State<BarcodeScanner> createState() => _BarcodeScannerState();
}

class _BarcodeScannerState extends State<BarcodeScanner> with SingleTickerProviderStateMixin {
  bool _torch = false;
  ScanResult? _detected;
  late final AnimationController _laser;

  @override
  void initState() {
    super.initState();
    _laser = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _detected = widget.mode == 'rack'
            ? const ScanResult(type: 'rack', code: 'RACK-B04-029X', rackId: 'B-Bay-04', zone: 'Zone B · Pharma', bins: 8)
            : const ScanResult(type: 'item', code: '8901030875632', name: 'Vitamin D3 60K IU', expectedRack: 'B-Bay-04');
      });
      _laser.stop();
    });
  }

  @override
  void dispose() {
    _laser.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wrongRack = _detected != null &&
        _detected!.type == 'item' &&
        _detected!.expectedRack != null &&
        _detected!.expectedRack != widget.currentRack;

    return Scaffold(
      backgroundColor: AppColors.scannerBg,
      body: Stack(
        children: [
          // Grid background stage
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          // Scan frame
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.78,
              child: AspectRatio(
                aspectRatio: 1.4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ..._corners(),
                    Opacity(opacity: 0.55, child: BarcodeViz(width: 220, height: 70, color: Colors.white)),
                    if (_detected == null)
                      AnimatedBuilder(
                        animation: _laser,
                        builder: (_, _) => Align(
                          alignment: Alignment(0, (_laser.value * 2 - 1) * 0.8),
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.transparent, Color(0xFF5BA0FF), Colors.transparent]),
                              boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 14)],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Tip text / detection card
          if (_detected == null)
            Align(
              alignment: const Alignment(0, 0.52),
              child: Text(
                widget.mode == 'rack' ? 'Align rack-label barcode within the frame' : 'Align item barcode within the frame',
                style: AppText.sans(size: 12, color: Colors.white70),
              ),
            )
          else
            Positioned(left: 14, right: 14, bottom: MediaQuery.of(context).size.height * 0.14, child: _detectionCard(wrongRack)),
          // Header
          Positioned(top: 0, left: 0, right: 0, child: _header()),
          // Bottom actions
          Positioned(left: 0, right: 0, bottom: 0, child: _bottomActions()),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const c = AppColors.primary;
    BorderSide s() => const BorderSide(color: c, width: 3);
    Widget corner(Alignment a, {bool top = false, bool bottom = false, bool left = false, bool right = false}) {
      return Align(
        alignment: a,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: Border(
              top: top ? s() : BorderSide.none,
              bottom: bottom ? s() : BorderSide.none,
              left: left ? s() : BorderSide.none,
              right: right ? s() : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft, top: true, left: true),
      corner(Alignment.topRight, top: true, right: true),
      corner(Alignment.bottomLeft, bottom: true, left: true),
      corner(Alignment.bottomRight, bottom: true, right: true),
    ];
  }

  Widget _header() {
    return Container(
      padding: EdgeInsets.fromLTRB(14, MediaQuery.of(context).padding.top + 12, 14, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99000000), Colors.transparent]),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassBtn(AppIcons.close, () => Navigator.pop(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.mode == 'rack' ? 'Scan Rack Barcode' : 'Scan Item Barcode', style: AppText.sans(size: 14, weight: FontWeight.w600, color: Colors.white)),
                if (widget.mode == 'item')
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Row(
                      children: [
                        const Icon(AppIcons.location, size: 10, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text('Rack: ', style: AppText.sans(size: 10.5, color: Colors.white70)),
                        Text(widget.currentRack, style: AppText.sans(size: 10.5, weight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _glassBtn(AppIcons.flash, () => setState(() => _torch = !_torch), highlighted: _torch),
        ],
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap, {bool highlighted = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: highlighted ? const Color(0x4DF59E0B) : const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _detectionCard(bool wrongRack) {
    final d = _detected!;
    final iconBg = wrongRack ? AppColors.redBg : (d.type == 'rack' ? AppColors.tintBlueBg : AppColors.greenBg);
    final iconFg = wrongRack ? AppColors.redFg : (d.type == 'rack' ? AppColors.primary : AppColors.greenFg);
    final iconData = wrongRack ? AppIcons.warning : (d.type == 'rack' ? AppIcons.grid : AppIcons.checkCircle);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: AppRadius.rLg,
        border: Border.all(color: wrongRack ? AppColors.redBorder : AppColors.blueBorder),
      ),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBg, borderRadius: AppRadius.rMd), child: Icon(iconData, size: 20, color: iconFg)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.type == 'rack' ? d.rackId! : d.name!, style: AppText.sans(size: 13, weight: FontWeight.w600)),
                Text(d.code, style: AppText.mono(size: 10.5, color: AppColors.ink3)),
                if (d.type == 'rack')
                  Text('${d.zone} · ${d.bins} bins', style: AppText.sans(size: 10.5, color: AppColors.ink3))
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: wrongRack
                        ? Text.rich(TextSpan(
                            style: AppText.sans(size: 10.5, color: AppColors.redFg),
                            children: [
                              const TextSpan(text: 'Expected at '),
                              TextSpan(text: d.expectedRack, style: AppText.sans(size: 10.5, weight: FontWeight.w700, color: AppColors.redFg)),
                              const TextSpan(text: ' · here in '),
                              TextSpan(text: widget.currentRack, style: AppText.sans(size: 10.5, weight: FontWeight.w700, color: AppColors.redFg)),
                            ],
                          ))
                        : Text.rich(TextSpan(
                            style: AppText.sans(size: 10.5, color: AppColors.greenFg),
                            children: [
                              const TextSpan(text: 'Correct rack '),
                              TextSpan(text: d.expectedRack, style: AppText.sans(size: 10.5, weight: FontWeight.w700, color: AppColors.greenFg)),
                            ],
                          )),
                  ),
              ],
            ),
          ),
          AppButton(label: d.type == 'rack' ? 'Set' : 'Add', small: true, onTap: () => Navigator.pop(context, d)),
        ],
      ),
    );
  }

  Widget _bottomActions() {
    Widget glass(String label, IconData icon, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x1FFFFFFF),
                borderRadius: AppRadius.rMd,
                border: Border.all(color: const Color(0x29FFFFFF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 6), Text(label, style: AppText.sans(size: 13, weight: FontWeight.w600, color: Colors.white))],
              ),
            ),
          ),
        );
    return Container(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 20 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0x80000000), Colors.transparent]),
      ),
      child: Row(children: [
        glass('Cancel', AppIcons.close, () => Navigator.pop(context)),
        const SizedBox(width: 8),
        glass('Manual Entry', AppIcons.edit, () => Navigator.pop(context)),
      ]),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0F141C));
    final line = Paint()..color = const Color(0x0AFFFFFF);
    for (double x = 0; x < size.width; x += 22) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), line);
    }
    for (double y = 0; y < size.height; y += 22) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
