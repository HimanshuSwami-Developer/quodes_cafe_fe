import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

TextStyle display(
  double size, {
  Color color = Q.text,
  FontWeight weight = FontWeight.w700,
  double spacing = 0.04,
}) => GoogleFonts.fredoka(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: size * spacing,
);

TextStyle body(
  double size, {
  Color color = Q.text,
  FontWeight weight = FontWeight.w500,
  double? height,
  double spacing = 0,
}) => GoogleFonts.nunito(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: spacing,
);

TextStyle label(double size, {Color color = Q.text3}) => GoogleFonts.nunito(
  fontSize: size,
  fontWeight: FontWeight.w800,
  color: color,
  letterSpacing: size * 0.12,
);

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Q.bg,
    colorScheme: const ColorScheme.dark(
      primary: Q.primary,
      secondary: Q.pink,
      surface: Q.surface,
      error: Q.red,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(
      base.textTheme,
    ).apply(bodyColor: Q.text, displayColor: Q.text),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Q.surfaceHi,
      contentTextStyle: body(14, weight: FontWeight.w700),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Q.primary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Q.surface,
      hintStyle: body(15, color: Q.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Q.borderHi),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Q.borderHi),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Q.primary, width: 1.5),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Q.link),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
