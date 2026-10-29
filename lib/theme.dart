import 'package:flutter/material.dart';

/// ShitLab ranglari.
class C {
  static const bg = Color(0xFF0F1318);
  static const bgDeep = Color(0xFF0B0E13);
  static const card = Color(0xFF161B23);
  static const card2 = Color(0xFF1B212B);
  static const line = Color(0xFF262E3B);
  static const line2 = Color(0xFF2C3442);
  static const text = Color(0xFFE8ECF2);
  static const text2 = Color(0xFFC9D1DD);
  static const soft = Color(0xFFA9B2C0);
  static const muted = Color(0xFF8A94A6);
  static const faint = Color(0xFF5D6778);
  static const amber = Color(0xFFF5B731);
  static const amberSoft = Color(0xFF2B2412);
  static const ink = Color(0xFF14110A);
  static const ok = Color(0xFF3FB37F);
  static const okSoft = Color(0xFF12291E);
  static const okText = Color(0xFF8FE6B8);
  static const bad = Color(0xFFE5534B);
  static const badSoft = Color(0xFF33201A);
  static const badText = Color(0xFFF5A49D);
  static const warnText = Color(0xFFF5C96A);
  static const l1 = Color(0xFFF2C230);
  static const l2 = Color(0xFF3FB37F);
  static const l3 = Color(0xFFF07A72);
  static const blue = Color(0xFF2F6FD6);
  static const blueprint = Color(0xFF0D2B4E);

  static Color phase(String p) {
    switch (p) {
      case 'L1':
        return l1;
      case 'L2':
        return l2;
      case 'L3':
        return l3;
      default:
        return text;
    }
  }

  static Color phaseSoft(String p) {
    switch (p) {
      case 'L1':
        return const Color(0xFF2E2810);
      case 'L2':
        return const Color(0xFF12291E);
      case 'L3':
        return const Color(0xFF331A18);
      default:
        return const Color(0xFF232A36);
    }
  }
}

const String monoFont = 'monospace';

TextStyle mono(double size, {Color color = C.text, FontWeight weight = FontWeight.w600}) =>
    TextStyle(fontFamily: monoFont, fontSize: size, color: color, fontWeight: weight);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: C.amber,
      onPrimary: C.ink,
      secondary: C.amber,
      surface: C.card,
      onSurface: C.text,
      error: C.bad,
    ),
    scaffoldBackgroundColor: C.bg,
  );
  return base.copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: C.card2,
      contentTextStyle: TextStyle(color: C.text, fontSize: 14),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.bg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      hintStyle: const TextStyle(color: C.faint),
      labelStyle: const TextStyle(color: C.muted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.line2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.amber, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.line2),
      ),
    ),
  );
}
