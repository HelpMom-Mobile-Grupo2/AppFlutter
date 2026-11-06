import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Paleta del Modo Compañero. Solo se usa en este archivo: las pantallas leen
// los colores desde Theme.of(context) o desde StatusColors.
const _primary = Color(0xFF4A6FA5);
const _accent = Color(0xFFE07A5F);
const _accentContainer = Color(0xFFFBE3DC);
const _surface = Color(0xFFFBFBFC);
const _surfaceContainer = Color(0xFFF0F4F8);
const _onSurface = Color(0xFF1A1C1E);

/// Colores del semáforo de salud. Las pantallas los usan desde aquí
/// (StatusColors.green), nunca con valores hexadecimales sueltos.
class StatusColors {
  StatusColors._();

  static const green = Color(0xFF2E7D32);
  static const greenContainer = Color(0xFFE8F5E9);
  static const amber = Color(0xFFEF6C00);
  static const amberContainer = Color(0xFFFFF3E0);
  static const red = Color(0xFFC62828);
  static const redContainer = Color(0xFFFFEBEE);
}

class AppTheme {
  AppTheme._();

  /// [useGoogleFonts] se apaga en los tests, donde no hay internet para
  /// descargar Plus Jakarta Sans.
  static ThemeData light({bool useGoogleFonts = true}) {
    // El texto sobre terracota va oscuro: blanco sobre #E07A5F no llega al
    // contraste mínimo (2.9:1), y #1A1C1E sí (5.8:1).
    final scheme = ColorScheme.fromSeed(seedColor: _primary).copyWith(
      primary: _primary,
      onPrimary: Colors.white,
      secondary: _accent,
      onSecondary: _onSurface,
      secondaryContainer: _accentContainer,
      onSecondaryContainer: _onSurface,
      surface: _surface,
      onSurface: _onSurface,
      surfaceContainer: _surfaceContainer,
      error: StatusColors.red,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme = useGoogleFonts
        ? GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        : base.textTheme;

    final roundedButton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    const minButtonSize = Size(48, 48);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: _surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _accent,
        foregroundColor: _onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: _onSurface,
        unselectedLabelColor: _onSurface,
        indicatorColor: _onSurface,
      ),
      cardTheme: CardThemeData(
        color: _surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minButtonSize,
          shape: roundedButton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minButtonSize,
          shape: roundedButton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: minButtonSize),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceContainer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: _surfaceContainer,
        indicatorColor: _accent,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: _surfaceContainer,
        indicatorColor: _accent,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
