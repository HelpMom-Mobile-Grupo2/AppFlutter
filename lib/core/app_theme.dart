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
const _onSurfaceMuted = Color(0xFF5F6B7A);

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

  /// Texto ámbar sobre amberContainer: #EF6C00 ahí no llega a 4.5:1.
  static const amberText = Color(0xFF9A4A00);
}

/// Tokens del diseño de Figma que no entran en el ColorScheme.
class AppColors {
  AppColors._();

  /// Tarjeta de alerta pendiente (frame 4).
  static const alertContainer = Color(0xFFFFF8E7);
  static const alertBorder = Color(0xFFF2C94C);

  /// Título de la alerta pendiente: ámbar oscuro sobre crema (5.6:1).
  static const alertTitle = Color(0xFF8A5A00);

  /// Borde de 1 dp de las tarjetas y de las filas de la misión.
  static const cardBorder = Color(0xFFE3E8EF);

  /// Terracota oscuro para TEXTO sobre blanco o terracota claro. El
  /// terracota #E07A5F se usa en rellenos, bordes e indicadores, pero como
  /// texto no llega al contraste mínimo (2.9:1 sobre blanco).
  static const accentText = Color(0xFFA8432A);
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
      onSurfaceVariant: _onSurfaceMuted,
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

    // Etiqueta e ícono de la pestaña activa en terracota (texto oscuro).
    Color navColor(Set<WidgetState> states) =>
        states.contains(WidgetState.selected)
        ? AppColors.accentText
        : _onSurfaceMuted;

    return base.copyWith(
      textTheme: textTheme,
      // Tarjetas blancas sobre el fondo gris azulado del Figma.
      scaffoldBackgroundColor: _surfaceContainer,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
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
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
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
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: _accentContainer,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: navColor(states)),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: navColor(states),
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: _accentContainer,
        selectedIconTheme: const IconThemeData(color: AppColors.accentText),
        unselectedIconTheme: const IconThemeData(color: _onSurfaceMuted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.accentText,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: _onSurfaceMuted,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
