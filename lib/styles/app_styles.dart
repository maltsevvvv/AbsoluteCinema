// ============================================================
//  lib/styles/app_styles.dart
// ============================================================
// Пункт 5 методички: стили вынесены в отдельный класс.
// Все цвета, размеры и TextStyle используются через AppStyles.
// ============================================================

import 'package:flutter/material.dart';

class AppStyles {
  // ── Цвета ─────────────────────────────────────────────────
  static const Color primary = Color(0xFFB71C1C); // кино-красный (иконка)
  static const Color accent = Color(0xFFFFD600); // жёлтый (кино)
  static const Color background = Color(0xFF0D0D0D); // почти чёрный фон
  static const Color surface = Color(0xFF1A1A1A); // карточки
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecond = Color(0xFFB0B0B0);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color pending = Color(0xFFFFB300);

  // ── Размеры отступов ──────────────────────────────────────
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;

  // ── Радиус скругления ─────────────────────────────────────
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;

  // ── Размеры постера ───────────────────────────────────────
  static const double posterW = 80.0;
  static const double posterH = 120.0;

  // ── Текстовые стили ───────────────────────────────────────
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: textSecond,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecond,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // ── Тема приложения ───────────────────────────────────────
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primary,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141414), // тёмный как Netflix
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: surface,
        ),
        cardTheme: CardThemeData(
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusS),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          // hintText просто исчезает при фокусе — никаких анимаций за рамку
          floatingLabelBehavior: FloatingLabelBehavior.never,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusS),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusS),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusS),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusS),
            borderSide: const BorderSide(color: error, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusS),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
          labelStyle: subtitle,
          hintStyle: caption,
        ),
      );
}
