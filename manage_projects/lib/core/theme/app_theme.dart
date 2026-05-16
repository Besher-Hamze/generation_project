import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  /// لون عميق للنصوص والتباين الخاص بالعلامة.
  static const Color brandDeep = Color(0xFF1E293B);
  static const Color brandAccent = Color(0xFFEA580C);

  /// الواجهة الافتراضية: فاتحة — أزرق أكاديمي مع لمسة برتقالية.
  static ThemeData light() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: Brightness.light,
      surface: const Color(0xFFFAFBFF),
      primary: const Color(0xFF1D4ED8),
      secondary: brandAccent,
      tertiary: const Color(0xFF7C3AED),
      error: const Color(0xFFDC2626),
    );

    final baseText = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
    ).textTheme;

    TextTheme arabic(TextTheme parent) =>
        GoogleFonts.tajawalTextTheme(parent).copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            textStyle: parent.displayLarge,
            fontWeight: FontWeight.w600,
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            textStyle: parent.displayMedium,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            textStyle: parent.headlineMedium,
            fontWeight: FontWeight.w600,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: baseScheme.surface,
      textTheme: arabic(baseText),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        indicatorColor: baseScheme.primary.withValues(alpha: 0.20),
        backgroundColor: Colors.white.withValues(alpha: 0.96),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: baseScheme.surface,
        foregroundColor: baseScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: brandDeep,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: baseScheme.outlineVariant.withValues(alpha: 0.45)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: baseScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: baseScheme.primary, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// واجهة داكنة (محفوظة للتوافق إن احتُجِت مستقبلاً).
  static ThemeData dark() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: Brightness.dark,
      surface: const Color(0xFF0F1419),
      primary: const Color(0xFF60A5FA),
      secondary: const Color(0xFFFB923C),
      tertiary: const Color(0xFFC4B5FD),
      error: const Color(0xFFFF8A80),
    );

    final baseText = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
    ).textTheme;

    TextTheme arabic(TextTheme parent) =>
        GoogleFonts.tajawalTextTheme(parent).copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            textStyle: parent.displayLarge,
            fontWeight: FontWeight.w600,
          ),
          displayMedium: GoogleFonts.playfairDisplay(
            textStyle: parent.displayMedium,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            textStyle: parent.headlineMedium,
            fontWeight: FontWeight.w600,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: baseScheme.surface,
      textTheme: arabic(baseText),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        indicatorColor: baseScheme.primary.withValues(alpha: 0.35),
        backgroundColor: const Color(0xFF1A2230).withValues(alpha: 0.94),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.transparent,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: Colors.white.withValues(alpha: 0.95),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF181F29),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: baseScheme.primary, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// تدرّج خلفيات للشاشات البطولية
  static BoxDecoration meshBackground(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    if (light) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            c.surface,
            Color.lerp(c.surfaceContainerHighest, c.primaryContainer, 0.28)!,
            Color.lerp(
              c.surface,
              c.secondaryContainer.withValues(alpha: 0.35),
              0.45,
            )!,
          ],
          stops: const [0, 0.52, 1],
        ),
      );
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          c.surface,
          Color.lerp(const Color(0xFF081214), c.primaryContainer, 0.12)!,
          const Color(0xFF080C0F),
        ],
        stops: const [0, 0.45, 1],
      ),
    );
  }

  /// ظل خفيف لبطاقات مميزة
  static List<BoxShadow> softGlow(BuildContext context) {
    final p = Theme.of(context).colorScheme.primary;
    final light = Theme.of(context).brightness == Brightness.light;
    return [
      BoxShadow(
        blurRadius: light ? 28 : 40,
        spreadRadius: light ? -4 : -8,
        offset: Offset(0, light ? 12 : 28),
        color: p.withValues(alpha: light ? 0.1 : 0.18),
      ),
    ];
  }
}
