// Shared UI primitives — Badge, Tag, KPIs, Card, Button, Stepper, Switch,
// Field, Tabs, Search, SectionHeader, BarcodeViz, AppHeader, StickyBar.
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

// ─── Status badge ─────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      kStatusDraft => (AppColors.grayFg, AppColors.grayBg),
      kStatusProgress => (AppColors.blueFg, AppColors.blueBg),
      kStatusSubmitted => (AppColors.orangeFg, AppColors.orangeBg),
      kStatusApproved => (AppColors.greenFg, AppColors.greenBg),
      kStatusPosted => (AppColors.purpleFg, AppColors.purpleBg),
      kStatusRejected => (AppColors.redFg, AppColors.redBg),
      _ => (AppColors.grayFg, AppColors.grayBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label ?? kStatusLabel[status] ?? status,
              style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: fg, letterSpacing: 0.1)),
        ],
      ),
    );
  }
}

// ─── Tag ──────────────────────────────────────────────────────
enum TagTone { normal, warn, danger, ok, info }

class AppTag extends StatelessWidget {
  final String text;
  final TagTone tone;
  final IconData? icon;
  final double fontSize;
  const AppTag(this.text, {super.key, this.tone = TagTone.normal, this.icon, this.fontSize = 10.5});

  @override
  Widget build(BuildContext context) {
    final (fg, bg, border) = switch (tone) {
      TagTone.normal => (AppColors.ink2, const Color(0xFFF2F5FA), AppColors.line2),
      TagTone.warn => (AppColors.orangeFg, AppColors.orangeBg, AppColors.orangeBorder),
      TagTone.danger => (AppColors.redFg, AppColors.redBg, AppColors.redBorder),
      TagTone.ok => (AppColors.greenFg, AppColors.greenBg, AppColors.greenBorder),
      TagTone.info => (AppColors.blueFg, AppColors.blueBg, AppColors.blueBorder),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: fontSize, color: fg), const SizedBox(width: 4)],
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: AppText.sans(size: fontSize, weight: FontWeight.w500, color: fg))),
        ],
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color background;
  final Color? borderColor;
  final bool dashed;
  final VoidCallback? onTap;
  final BoxDecoration? overrideDecoration;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.background = AppColors.card,
    this.borderColor,
    this.dashed = false,
    this.onTap,
    this.overrideDecoration,
  });

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: overrideDecoration ??
          BoxDecoration(
            color: background,
            borderRadius: AppRadius.rLg,
            border: Border.all(color: borderColor ?? AppColors.line),
          ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: AppRadius.rLg, onTap: onTap, child: card);
  }
}

// ─── Buttons ──────────────────────────────────────────────────
enum BtnVariant { primary, ghost, danger, warn, success, muted }

class AppButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final BtnVariant variant;
  final bool small;
  final bool block;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? customChild;
  const AppButton({
    super.key,
    this.label,
    this.icon,
    this.trailingIcon,
    this.variant = BtnVariant.primary,
    this.small = false,
    this.block = false,
    this.enabled = true,
    this.onTap,
    this.customChild,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, shadow) = switch (variant) {
      BtnVariant.primary => (AppColors.primary, Colors.white, null, _primaryShadow),
      BtnVariant.ghost => (AppColors.card, AppColors.ink, AppColors.line, null),
      BtnVariant.danger => (AppColors.card, AppColors.redFg, AppColors.redBorder, null),
      BtnVariant.warn => (AppColors.card, AppColors.orangeFg, AppColors.orangeBorder, null),
      BtnVariant.success => (AppColors.success, Colors.white, null, null),
      BtnVariant.muted => (AppColors.line2, AppColors.ink2, null, null),
    };
    final fontSize = small ? 12.0 : 13.0;
    final iconOnly = label == null && customChild == null && icon != null;
    final pad = iconOnly
        ? EdgeInsets.all(small ? 6 : 8)
        : small
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    final radius = small ? AppRadius.rSm : AppRadius.rMd;

    final content = customChild ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: fontSize + 1, color: fg),
            if (icon != null && label != null) const SizedBox(width: 6),
            if (label != null)
              Flexible(child: Text(label!, overflow: TextOverflow.ellipsis, style: AppText.sans(size: fontSize, weight: FontWeight.w600, color: fg))),
            if (trailingIcon != null) ...[const SizedBox(width: 6), Icon(trailingIcon, size: fontSize + 1, color: fg)],
          ],
        );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: bg,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: border != null ? Border.all(color: border) : null,
              boxShadow: shadow,
            ),
            child: Container(
              padding: pad,
              width: block ? double.infinity : null,
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  static const _primaryShadow = [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1)),
    BoxShadow(color: Color(0x4D277DFE), blurRadius: 14, offset: Offset(0, 4)),
  ];
}

/// Small square icon button (header / toolbar).
class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  const IconBtn({super.key, required this.icon, this.onTap, this.size = 32, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 16, color: color ?? AppColors.ink2),
        ),
      ),
    );
  }
}

// ─── KPI grid ─────────────────────────────────────────────────
enum KpiTint { none, blue, green, red, orange }

enum KpiTone { none, pos, neg }

class KpiData {
  final String label;
  final String value;
  final KpiTint tint;
  final KpiTone tone;
  const KpiData(this.label, this.value, {this.tint = KpiTint.none, this.tone = KpiTone.none});
}

class KpiGrid extends StatelessWidget {
  final List<KpiData> items;
  final int cols;
  const KpiGrid(this.items, {super.key, this.cols = 2});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: cols == 4 ? 0.92 : 2.4,
      children: items.map(_cell).toList(),
    );
  }

  Widget _cell(KpiData k) {
    final (bg, border) = switch (k.tint) {
      KpiTint.blue => (AppColors.tintBlueBg, AppColors.tintBlueBorder),
      KpiTint.green => (AppColors.tintGreenBg, AppColors.tintGreenBorder),
      KpiTint.red => (AppColors.tintRedBg, AppColors.tintRedBorder),
      KpiTint.orange => (AppColors.tintOrangeBg, AppColors.tintOrangeBorder),
      KpiTint.none => (AppColors.card, AppColors.line),
    };
    final valColor = switch (k.tone) {
      KpiTone.pos => AppColors.greenFg,
      KpiTone.neg => AppColors.redFg,
      KpiTone.none => AppColors.ink,
    };
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.rMd, border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(k.label, style: AppText.sans(size: 10.5, weight: FontWeight.w500, color: AppColors.ink3)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(k.value, style: AppText.sans(size: 18, weight: FontWeight.w700, color: valColor, letterSpacing: -0.36, tabular: true)),
          ),
        ],
      ),
    );
  }
}

// ─── Stepper ──────────────────────────────────────────────────
class NumStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  const NumStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 99999});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          _btn('−', () => onChanged((value - 1).clamp(min, max))),
          Expanded(
            child: Center(
              child: Text('$value', style: AppText.sans(size: 13, weight: FontWeight.w600, tabular: true)),
            ),
          ),
          _btn('+', () => onChanged((value + 1).clamp(min, max))),
        ],
      ),
    );
  }

  Widget _btn(String s, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 32,
          child: Center(child: Text(s, style: AppText.sans(size: 16, color: AppColors.ink2))),
        ),
      );
}

// ─── Toggle switch ────────────────────────────────────────────
class AppSwitchRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget label;
  final String? hint;
  const AppSwitchRow({super.key, required this.value, required this.onChanged, required this.label, this.hint});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(style: AppText.sans(size: 12, weight: FontWeight.w500), child: label),
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(hint!, style: AppText.sans(size: 10.5, color: AppColors.ink3)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : const Color(0xFFD7DDE6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Field wrapper ────────────────────────────────────────────
class Field extends StatelessWidget {
  final String? label;
  final bool required;
  final String? hint;
  final Widget child;
  const Field({super.key, this.label, this.required = false, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text.rich(TextSpan(
              text: label,
              style: AppText.sans(size: 11, weight: FontWeight.w500, color: AppColors.ink2),
              children: required ? [TextSpan(text: ' *', style: AppText.sans(size: 11, color: AppColors.redFg))] : null,
            )),
          ),
        child,
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(hint!, style: AppText.sans(size: 10.5, color: AppColors.ink3)),
          ),
      ],
    );
  }
}

/// Bordered input shell shared by text fields / selects.
InputDecoration appInputDecoration({String? hintText, Widget? prefixIcon, EdgeInsets? contentPadding}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: AppRadius.rMd,
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.card,
    hintText: hintText,
    hintStyle: AppText.sans(size: 13, color: AppColors.ink4),
    prefixIcon: prefixIcon,
    prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 0),
    contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    border: border(AppColors.line),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.primary, 1.5),
  );
}

// ─── Tabs ─────────────────────────────────────────────────────
class TabItem {
  final String id;
  final String label;
  final int? count;
  const TabItem(this.id, this.label, {this.count});
}

class AppTabs extends StatelessWidget {
  final List<TabItem> tabs;
  final String value;
  final ValueChanged<String> onChanged;
  const AppTabs({super.key, required this.tabs, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        child: Row(
          children: tabs.map((t) {
            final active = t.id == value;
            return GestureDetector(
              onTap: () => onChanged(t.id),
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(t.label, style: AppText.sans(size: 12, weight: FontWeight.w600, color: active ? AppColors.primary : AppColors.ink3)),
                    if (t.count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: active ? AppColors.blueBg : AppColors.line2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${t.count}', style: AppText.sans(size: 10, weight: FontWeight.w600, color: active ? AppColors.primary : AppColors.ink3)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Search field ─────────────────────────────────────────────
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;
  final bool autofocus;
  const SearchField({
    super.key,
    required this.controller,
    this.placeholder = 'Search...',
    this.onChanged,
    this.onFilter,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            onChanged: onChanged,
            style: AppText.sans(size: 13),
            decoration: appInputDecoration(
              hintText: placeholder,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 10, right: 6),
                child: Icon(AppIcons.search, size: 15, color: AppColors.ink4),
              ),
            ),
          ),
        ),
        if (onFilter != null) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: AppButton(variant: BtnVariant.ghost, icon: AppIcons.tune, onTap: onFilter),
          ),
        ],
      ],
    );
  }
}

// ─── Section header ───────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final Widget title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
      child: Row(
        children: [
          Expanded(
            child: DefaultTextStyle(
              style: AppText.sans(size: 11, weight: FontWeight.w700, color: AppColors.ink2, letterSpacing: 0.44),
              child: title,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Uppercase card-section label ("BASICS", "COUNT TYPE", …).
class CardLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const CardLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final label = Text(text.toUpperCase(),
        style: AppText.sans(size: 11, weight: FontWeight.w600, color: AppColors.ink2, letterSpacing: 0.44));
    if (trailing == null) return Padding(padding: const EdgeInsets.only(bottom: 10), child: label);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Flexible(child: label), const SizedBox(width: 8), Flexible(child: trailing!)],
      ),
    );
  }
}

// ─── Key/value row ────────────────────────────────────────────
class KvRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;
  final bool last;
  const KvRow(this.label, this.value, {super.key, this.valueColor, this.mono = false, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.line2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.sans(size: 12, color: AppColors.ink3)),
          mono
              ? Text(value, style: AppText.mono(size: 12, color: valueColor ?? AppColors.ink))
              : Text(value, style: AppText.sans(size: 12, weight: FontWeight.w600, color: valueColor ?? AppColors.ink, tabular: true)),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.primary50, borderRadius: AppRadius.rXl),
            child: const Icon(AppIcons.search, size: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(message, style: AppText.sans(size: 12, color: AppColors.ink3)),
        ],
      ),
    );
  }
}

// ─── Decorative barcode ───────────────────────────────────────
class BarcodeViz extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  const BarcodeViz({super.key, this.width = 130, this.height = 22, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, height), painter: _BarcodePainter(color));
  }
}

class _BarcodePainter extends CustomPainter {
  final Color color;
  _BarcodePainter(this.color);
  // Deterministic stripe pattern from components.jsx.
  static const _pattern = '231132132313231231323213132321323';

  @override
  void paint(Canvas canvas, Size size) {
    final stripes = _pattern.split('');
    double totalUnits = 0;
    for (final c in stripes) {
      totalUnits += (c == '1' ? 2 : 1.5) + 1.5; // bar + gap
    }
    final scale = size.width / totalUnits;
    double x = 0;
    for (final c in stripes) {
      final w = (c == '1' ? 2.0 : 1.5) * scale;
      final h = c == '1' ? size.height : (c == '2' ? size.height * 0.8 : size.height * 0.6);
      final opacity = c == '1' ? 1.0 : (c == '2' ? 0.85 : 0.6);
      final paint = Paint()..color = color.withValues(alpha: opacity);
      canvas.drawRect(Rect.fromLTWH(x, (size.height - h) / 2, w, h), paint);
      x += w + 1.5 * scale;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter old) => old.color != color;
}

// ─── App header (sticky) ──────────────────────────────────────
class AppHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final Widget title;
  final String? subtitle;
  final String? status;
  final List<Widget> actions;
  const AppHeader({
    super.key,
    this.onBack,
    required this.title,
    this.subtitle,
    this.status,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconBtn(icon: AppIcons.chevronLeft, onTap: onBack),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: AppText.sans(size: 14, weight: FontWeight.w600, height: 1.2),
                  child: title,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(subtitle!, style: AppText.sans(size: 11, color: AppColors.ink3), overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (status != null) Padding(padding: const EdgeInsets.only(left: 8), child: StatusBadge(status: status!)),
          for (final a in actions) Padding(padding: const EdgeInsets.only(left: 6), child: a),
        ],
      ),
    );
  }
}

// ─── Sticky bottom action bar ─────────────────────────────────
class StickyBar extends StatelessWidget {
  final List<Widget> children;
  const StickyBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(children: children),
    );
  }
}
