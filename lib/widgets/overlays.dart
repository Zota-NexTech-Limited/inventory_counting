// Bottom-sheet + confirmation-modal helpers matching the design's scrim,
// rounded top corners, handle bar, and pop/rise animations.
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'primitives.dart';

/// Bottom sheet with handle + header. The [builder] gets a StateSetter so the
/// sheet content can hold local state (search query, picked item, etc.).
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context, StateSetter setSheetState) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.scrim,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final maxH = MediaQuery.of(ctx).size.height * 0.86;
          return Container(
            constraints: BoxConstraints(maxHeight: maxH),
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(ctx).viewInsets.bottom + 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.fromLTRB(0, 6, 0, 10),
                  decoration: BoxDecoration(color: const Color(0xFFD7DDE6), borderRadius: BorderRadius.circular(999)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(title, style: AppText.sans(size: 14, weight: FontWeight.w600))),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: AppButton(variant: BtnVariant.ghost, icon: AppIcons.close, small: true, onTap: () => Navigator.of(ctx).pop()),
                      ),
                    ],
                  ),
                ),
                Flexible(child: SingleChildScrollView(child: builder(ctx, setSheetState))),
              ],
            ),
          );
        },
      );
    },
  );
}

enum ModalTone { primary, warn, danger, ok }

/// Centered confirmation dialog with optional circular tinted icon.
Future<T?> showAppModal<T>({
  required BuildContext context,
  IconData? icon,
  ModalTone tone = ModalTone.primary,
  required String title,
  required String body,
  required List<Widget> actions,
}) {
  final (iconBg, iconFg) = switch (tone) {
    ModalTone.primary => (AppColors.primary50, AppColors.primary),
    ModalTone.warn => (AppColors.orangeBg, AppColors.orangeFg),
    ModalTone.danger => (AppColors.redBg, AppColors.redFg),
    ModalTone.ok => (AppColors.greenBg, AppColors.greenFg),
  };
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: AppColors.scrim,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, _, _) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, _) {
      final curved = CurvedAnimation(parent: anim, curve: const Cubic(.2, .9, .4, 1.2));
      return Transform.scale(
        scale: 0.95 + 0.05 * curved.value,
        child: Opacity(
          opacity: anim.value.clamp(0, 1),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Material(
                color: AppColors.card,
                borderRadius: AppRadius.rXl,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                          child: Icon(icon, size: 20, color: iconFg),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(title, textAlign: TextAlign.center, style: AppText.sans(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(body, textAlign: TextAlign.center, style: AppText.sans(size: 12, color: AppColors.ink3, height: 1.4)),
                      const SizedBox(height: 12),
                      Row(children: actions),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
