// Pill choice-chip used by filter sheets, scope pickers, segmented selectors.
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class ChoiceChipX extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final bool showCheck;
  final bool showClose;
  final bool dashed;
  const ChoiceChipX({
    super.key,
    required this.label,
    this.active = false,
    this.onTap,
    this.leadingIcon,
    this.showCheck = false,
    this.showClose = false,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.primary600 : AppColors.ink2;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary50 : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheck && active) ...[const Icon(AppIcons.check, size: 11, color: AppColors.primary600), const SizedBox(width: 4)],
            if (leadingIcon != null) ...[Icon(leadingIcon, size: 12, color: fg), const SizedBox(width: 4)],
            Text(label, style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: fg)),
            if (showClose) ...[const SizedBox(width: 5), Icon(AppIcons.close, size: 11, color: fg)],
          ],
        ),
      ),
    );
  }
}

/// Avatar chip used in team/counter assignment.
class AvatarChip extends StatelessWidget {
  final String name;
  final Color avatarBg;
  final Color avatarFg;
  final VoidCallback? onRemove;
  const AvatarChip({super.key, required this.name, required this.avatarBg, required this.avatarFg, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').map((s) => s.isEmpty ? '' : s[0]).join();
    return Container(
      padding: const EdgeInsets.fromLTRB(3, 3, 8, 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.blueBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
            child: Text(initials, style: AppText.sans(size: 10, weight: FontWeight.w700, color: avatarFg)),
          ),
          const SizedBox(width: 6),
          Text(name, style: AppText.sans(size: 11.5, color: AppColors.ink2)),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(onTap: onRemove, child: const Icon(AppIcons.close, size: 11, color: AppColors.ink3)),
          ],
        ],
      ),
    );
  }
}

/// Dashed "add" chip.
class AddChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const AddChip({super.key, this.label = 'Add', this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: AppColors.line),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.add, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: AppText.sans(size: 11.5, weight: FontWeight.w500, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
