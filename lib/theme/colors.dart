import 'package:flutter/material.dart';

/// Quodes Gaming palette (from the design canvas).
class Q {
  static const bg = Color(0xFF0A1330);
  static const surface = Color(0xFF111C42);
  static const surfaceHi = Color(0xFF152A66);
  static const surfaceLo = Color(0xFF16245A);
  static const border = Color(0xFF22356F);
  static const borderHi = Color(0xFF31478A);
  static const primary = Color(0xFF2F6BFF);
  static const primaryShadow = Color(0xFF1A3FA8);
  static const primaryMid = Color(0xFF2F4E9E);
  static const link = Color(0xFF7FB0FF);
  static const linkHi = Color(0xFFA9C8FF);
  static const pink = Color(0xFFFF4D9D);
  static const pinkSoft = Color(0xFFFF7AB8);
  static const pinkText = Color(0xFFFF9CCB);
  static const pinkBg = Color(0xFF341634);
  static const cyan = Color(0xFF3FD0FF);
  static const green = Color(0xFF4ADE9A);
  static const greenText = Color(0xFF86EFBF);
  static const greenBg = Color(0xFF0E2C2B);
  static const greenBorder = Color(0xFF1D5A47);
  static const greenDeep = Color(0xFF15803D);
  static const amber = Color(0xFFFFC24D);
  static const amberText = Color(0xFFFFD27A);
  static const amberBg = Color(0xFF2B2310);
  static const amberBorder = Color(0xFF6B5420);
  static const red = Color(0xFFFF7A8A);
  static const redText = Color(0xFFFFB3BD);
  static const redBg = Color(0xFF361525);
  static const redBorder = Color(0xFF6E2A3A);
  static const text = Color(0xFFEAF1FF);
  static const text2 = Color(0xFFC6D3F0);
  static const text3 = Color(0xFF9FB2D9);
  static const muted = Color(0xFF8EA2CC);
}

Color hexColor(String hex, [Color fallback = Q.primary]) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(v);
}
