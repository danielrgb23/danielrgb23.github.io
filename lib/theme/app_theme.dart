import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central color palette, shared across the whole app.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF0D0221);
  static const bgPanel = Color(0xFF170B33);
  static const bgPanelAlt = Color(0xFF1F1044);
  static const cyan = Color(0xFF2DE2FF);
  static const magenta = Color(0xFFFF3CAA);
  static const gold = Color(0xFFFFCD3C);
  static const text = Color(0xFFF1EAFF);
  static const textDim = Color(0xFFA793CF);
  static const border = Color(0xFF3A1F66);
}

/// Central typography: "Press Start 2P" for pixel/arcade headings and short
/// labels, "Space Mono" for anything meant to be read at length.
class AppText {
  AppText._();

  static TextStyle get pixel => GoogleFonts.pressStart2p();
  static TextStyle get mono => GoogleFonts.spaceMono();

  static final TextStyle kicker = pixel.copyWith(
    fontSize: 11,
    color: AppColors.magenta,
    letterSpacing: 1,
  );

  static final TextStyle h1 = pixel.copyWith(
    fontSize: 26,
    height: 1.5,
    color: AppColors.text,
  );

  static final TextStyle h2 = pixel.copyWith(
    fontSize: 18,
    height: 1.5,
    color: AppColors.cyan,
  );

  static final TextStyle body = mono.copyWith(
    fontSize: 15,
    height: 1.65,
    color: AppColors.textDim,
  );

  static final TextStyle button = pixel.copyWith(
    fontSize: 11,
    color: AppColors.cyan,
  );

  static final TextStyle small = mono.copyWith(
    fontSize: 12,
    color: AppColors.textDim,
  );
}
