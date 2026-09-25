import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_settings.dart';

/// One full color set. The app has a dark ("arcade night") and a light
/// ("arcade day") palette; the lamp switch flips between them.
class _Palette {
  const _Palette({
    required this.bg,
    required this.bgPanel,
    required this.bgPanelAlt,
    required this.cyan,
    required this.magenta,
    required this.gold,
    required this.text,
    required this.textDim,
    required this.border,
  });
  final Color bg, bgPanel, bgPanelAlt, cyan, magenta, gold, text, textDim, border;
}

const _dark = _Palette(
  bg: Color(0xFF0D0221),
  bgPanel: Color(0xFF170B33),
  bgPanelAlt: Color(0xFF1F1044),
  cyan: Color(0xFF2DE2FF),
  magenta: Color(0xFFFF3CAA),
  gold: Color(0xFFFFCD3C),
  text: Color(0xFFF1EAFF),
  textDim: Color(0xFFA793CF),
  border: Color(0xFF3A1F66),
);

const _light = _Palette(
  bg: Color(0xFFF6F1FF),
  bgPanel: Color(0xFFFFFFFF),
  bgPanelAlt: Color(0xFFEFE6FF),
  cyan: Color(0xFF0682A3),
  magenta: Color(0xFFC91E86),
  gold: Color(0xFFA86F00),
  text: Color(0xFF1B0B3A),
  textDim: Color(0xFF5C4A82),
  border: Color(0xFFCBB8EE),
);

/// Central color palette, resolved against the current theme setting.
class AppColors {
  AppColors._();

  static _Palette get _p => AppSettings.instance.isDark ? _dark : _light;

  static Color get bg => _p.bg;
  static Color get bgPanel => _p.bgPanel;
  static Color get bgPanelAlt => _p.bgPanelAlt;
  static Color get cyan => _p.cyan;
  static Color get magenta => _p.magenta;
  static Color get gold => _p.gold;
  static Color get text => _p.text;
  static Color get textDim => _p.textDim;
  static Color get border => _p.border;
}

/// Central typography: "Press Start 2P" for pixel/arcade headings and short
/// labels, "Space Mono" for anything meant to be read at length.
class AppText {
  AppText._();

  static TextStyle get pixel => GoogleFonts.pressStart2p();
  static TextStyle get mono => GoogleFonts.spaceMono();

  static TextStyle get kicker => pixel.copyWith(
    fontSize: 11,
    color: AppColors.magenta,
    letterSpacing: 1,
  );

  static TextStyle get h1 => pixel.copyWith(
    fontSize: 26,
    height: 1.5,
    color: AppColors.text,
  );

  static TextStyle get h2 => pixel.copyWith(
    fontSize: 18,
    height: 1.5,
    color: AppColors.cyan,
  );

  static TextStyle get body => mono.copyWith(
    fontSize: 15,
    height: 1.65,
    color: AppColors.textDim,
  );

  static TextStyle get button => pixel.copyWith(
    fontSize: 11,
    color: AppColors.cyan,
  );

  static TextStyle get small => mono.copyWith(
    fontSize: 12,
    color: AppColors.textDim,
  );
}
