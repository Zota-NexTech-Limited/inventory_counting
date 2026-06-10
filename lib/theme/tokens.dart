// Design tokens for the Inventory Counting module.
// Mirrors styles.css :root + compact density + soft radius (the design defaults).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color palette — 1:1 with the CSS custom properties.
class AppColors {
  // Brand / primary
  static const primary = Color(0xFF277DFE);
  static const primary50 = Color(0xFFEEF4FF);
  static const primary100 = Color(0xFFDCE8FF);
  static const primary600 = Color(0xFF1E63D6);

  // Ink (text)
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF334155);
  static const ink3 = Color(0xFF64748B);
  static const ink4 = Color(0xFF94A3B8);

  static const line = Color(0xFFE5E9F0);
  static const line2 = Color(0xFFEEF1F5);
  static const bg = Color(0xFFF4F6FA);
  static const card = Color(0xFFFFFFFF);

  // Semantic foreground / background pairs
  static const grayFg = Color(0xFF475569);
  static const grayBg = Color(0xFFEEF1F5);
  static const blueFg = Color(0xFF1E63D6);
  static const blueBg = Color(0xFFE8F1FF);
  static const orangeFg = Color(0xFFB45309);
  static const orangeBg = Color(0xFFFFF4E0);
  static const greenFg = Color(0xFF16803C);
  static const greenBg = Color(0xFFE4F6EA);
  static const purpleFg = Color(0xFF6D28D9);
  static const purpleBg = Color(0xFFEFE7FF);
  static const redFg = Color(0xFFB91C1C);
  static const redBg = Color(0xFFFFE7EC);

  // Borders for tinted surfaces
  static const orangeBorder = Color(0xFFFCE2B3);
  static const redBorder = Color(0xFFFBCED7);
  static const greenBorder = Color(0xFFC7EAD3);
  static const blueBorder = Color(0xFFCFE0FF);

  // KPI tints
  static const tintBlueBg = Color(0xFFF4F8FF);
  static const tintBlueBorder = Color(0xFFDCE8FF);
  static const tintGreenBg = Color(0xFFF2FBF5);
  static const tintGreenBorder = Color(0xFFCFEAD7);
  static const tintRedBg = Color(0xFFFEF4F6);
  static const tintRedBorder = Color(0xFFFBCED7);
  static const tintOrangeBg = Color(0xFFFFF9EE);
  static const tintOrangeBorder = Color(0xFFFCE2B3);

  static const success = Color(0xFF16A34A);
  static const successHover = Color(0xFF15803D);

  // Accent (timeline warn dot, etc.)
  static const orangeAccent = Color(0xFFF59E0B);

  // Dark surfaces (scanner / scrim)
  static const scannerBg = Color(0xFF0B0E14);
  static const scrim = Color(0x660F1116); // rgba(15,17,22,.40)
}

/// Icon set — semantic names mapped to Material glyphs, so the same concept
/// uses the same glyph everywhere and an icon can be swapped in one place.
class AppIcons {
  // Status / feedback
  static const check = Icons.check;
  static const checkCircle = Icons.check_circle_outline;
  static const warning = Icons.warning_amber_rounded;
  static const error = Icons.error_outline;
  static const offline = Icons.cloud_off;

  // Navigation / disclosure
  static const close = Icons.close;
  static const chevronRight = Icons.chevron_right;
  static const chevronLeft = Icons.chevron_left;
  static const caretDown = Icons.keyboard_arrow_down;
  static const caretUp = Icons.keyboard_arrow_up;

  // Actions
  static const add = Icons.add;
  static const search = Icons.search;
  static const refresh = Icons.refresh;
  static const send = Icons.send;
  static const save = Icons.save_outlined;
  static const edit = Icons.edit_outlined;
  static const download = Icons.file_download_outlined;
  static const print = Icons.print_outlined;
  static const tune = Icons.tune;
  static const scan = Icons.qr_code_scanner;
  static const flash = Icons.flashlight_on;
  static const mic = Icons.mic_none;
  static const play = Icons.play_arrow;
  static const login = Icons.login;
  static const pin = Icons.push_pin_outlined;
  static const attach = Icons.attach_file;
  static const visibility = Icons.visibility_outlined;
  static const visibilityOff = Icons.visibility_off_outlined;

  // Entities / objects
  static const item = Icons.inventory_2_outlined;
  static const location = Icons.place_outlined;
  static const warehouse = Icons.warehouse_outlined;
  static const sku = Icons.sell_outlined;
  static const layers = Icons.layers_outlined;
  static const grid = Icons.grid_view;
  static const schedule = Icons.schedule;
  static const calendar = Icons.calendar_today;
  static const person = Icons.person_outline;
  static const notifications = Icons.notifications_none;
  static const image = Icons.image_outlined;
  static const document = Icons.description_outlined;
  static const article = Icons.article_outlined;
  static const flag = Icons.flag_outlined;
  static const freeze = Icons.ac_unit;
}

/// Soft radius scale (the design default).
class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 18;
  static const double pill = 999;

  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
}

/// Compact density spacing (the design default).
class AppSpace {
  static const double pad = 10; // screen / card padding
  static const double row = 8; // gap between stacked cards
}

/// Typography helpers — Inter for body, JetBrains Mono for codes/IDs.
class AppText {
  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  static TextStyle sans({
    double size = 12.5,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double letterSpacing = -0.005 * 12.5,
    double? height,
    bool tabular = false,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: tabular ? _tabular : null,
    );
  }

  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.ink2,
    double? height,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.005 * size,
      height: height,
      fontFeatures: _tabular,
    );
  }
}

/// Currency + number formatting — matches data.jsx fmtINR / fmtNum.
String fmtINR(num n) {
  if (n == 0) return '₹0';
  final a = n.abs();
  String s;
  if (a >= 100000) {
    s = '₹${(a / 100000).toStringAsFixed(2)}L';
  } else if (a >= 1000) {
    s = '₹${(a / 1000).toStringAsFixed(1)}k';
  } else {
    s = '₹${a % 1 == 0 ? a.toInt() : a}';
  }
  return n < 0 ? '−$s' : s;
}

/// Indian digit grouping (en-IN), e.g. 1200 -> "1,200", 1234567 -> "12,34,567".
String fmtNum(num n) {
  final neg = n < 0;
  final digits = n.abs().toInt().toString();
  if (digits.length <= 3) return neg ? '−$digits' : digits;

  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  final s = '${groups.join(',')},$last3';
  return neg ? '−$s' : s;
}

const String kStatusDraft = 'draft';
const String kStatusProgress = 'progress';
const String kStatusSubmitted = 'submitted';
const String kStatusApproved = 'approved';
const String kStatusPosted = 'posted';
const String kStatusRejected = 'rejected';

const Map<String, String> kStatusLabel = {
  kStatusDraft: 'Draft',
  kStatusProgress: 'In Progress',
  kStatusSubmitted: 'Submitted',
  kStatusApproved: 'Approved',
  kStatusPosted: 'Posted',
  kStatusRejected: 'Rejected',
};
