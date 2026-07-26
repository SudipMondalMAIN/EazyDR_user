import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color hexToColor(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

const double kRadius = 16;
const double kRadiusSm = 10;
const double kRadiusLg = 24;

/// Builds a full ThemeData at runtime from the superadmin-controlled
/// app-config values (theme_mode, primary_color, secondary_color) —
/// mirrors the reference index.html design tokens (teal light / teal-on-dark,
/// 16px card radius, soft shadows, Plus Jakarta Sans + Inter).
ThemeData buildAppTheme({required bool isDark, required String primaryHex, required String secondaryHex}) {
  final primary = hexToColor(primaryHex);
  final secondary = hexToColor(secondaryHex);

  final bg = isDark ? const Color(0xFF0A1414) : const Color(0xFFF4F7F7);
  final surface = isDark ? const Color(0xFF101D1C) : const Color(0xFFFFFFFF);
  final surface2 = isDark ? const Color(0xFF162624) : const Color(0xFFEEF3F3);
  final text = isDark ? const Color(0xFFE6F1EF) : const Color(0xFF0C1A19);
  final text2 = isDark ? const Color(0xFF9DB4B0) : const Color(0xFF526360);
  final border = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.09);
  final onPrimary = isDark ? const Color(0xFF04211E) : Colors.white;

  final headingFont = GoogleFonts.plusJakartaSansTextTheme();
  final bodyFont = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: Colors.white,
      error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      onError: Colors.white,
      surface: surface,
      onSurface: text,
    ),
    dividerColor: border,
    cardColor: surface,
    textTheme: bodyFont.apply(bodyColor: text, displayColor: text).copyWith(
          headlineLarge: headingFont.headlineLarge?.copyWith(color: text, fontWeight: FontWeight.w800),
          headlineMedium: headingFont.headlineMedium?.copyWith(color: text, fontWeight: FontWeight.w700),
          headlineSmall: headingFont.headlineSmall?.copyWith(color: text, fontWeight: FontWeight.w700),
          titleLarge: headingFont.titleLarge?.copyWith(color: text, fontWeight: FontWeight.w700),
          titleMedium: headingFont.titleMedium?.copyWith(color: text, fontWeight: FontWeight.w600),
          bodySmall: bodyFont.bodySmall?.copyWith(color: text2),
          bodyMedium: bodyFont.bodyMedium?.copyWith(color: text2),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface.withOpacity(0.85),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: text,
      titleTextStyle: headingFont.titleLarge?.copyWith(color: text, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius), side: BorderSide(color: border)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSm), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSm), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSm), borderSide: BorderSide(color: primary, width: 1.4)),
      hintStyle: TextStyle(color: text2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: headingFont.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: text,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: text2,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface2,
      labelStyle: TextStyle(color: text, fontSize: 13),
      shape: StadiumBorder(side: BorderSide(color: border)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    extensions: [
      AppColorTokens(
        surface2: surface2,
        text2: text2,
        text3: isDark ? const Color(0xFF6D8480) : const Color(0xFF7D8C8A),
        border: border,
        primarySoft: primary.withOpacity(0.1),
        successColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
        successSoft: (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)).withOpacity(0.12),
        dangerColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        dangerSoft: (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)).withOpacity(0.1),
        accentColor: secondary,
        accentSoft: secondary.withOpacity(0.12),
      ),
    ],
  );
}

/// Extra design tokens (soft backgrounds, tertiary text) not modeled by
/// Flutter's default ColorScheme but present throughout the reference UI.
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color surface2, text2, text3, border, primarySoft, successColor, successSoft, dangerColor, dangerSoft, accentColor, accentSoft;

  AppColorTokens({
    required this.surface2,
    required this.text2,
    required this.text3,
    required this.border,
    required this.primarySoft,
    required this.successColor,
    required this.successSoft,
    required this.dangerColor,
    required this.dangerSoft,
    required this.accentColor,
    required this.accentSoft,
  });

  @override
  AppColorTokens copyWith() => this;

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) => this;
}

extension AppThemeContext on BuildContext {
  AppColorTokens get tokens => Theme.of(this).extension<AppColorTokens>()!;
}
