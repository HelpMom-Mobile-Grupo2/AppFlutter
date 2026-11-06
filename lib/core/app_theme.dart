import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Paleta del Modo Compañero. Solo se usa en este archivo: las pantallas leen
// los colores desde Theme.of(context).
const _primary = Color(0xFF4A6FA5);
const _accent = Color(0xFFE07A5F);
const _accentContainer = Color(0xFFFBE3DC);
const _surface = Color(0xFFFBFBFC);
const _surfaceContainer = Color(0xFFF0F4F8);
const _onSurface = Color(0xFF1A1C1E);

const _green = Color(0xFF2E7D32);
const _greenContainer = Color(0xFFE8F5E9);
const _amber = Color(0xFFEF6C00);
const _amberContainer = Color(0xFFFFF3E0);
const _red = Color(0xFFC62828);
const _redContainer = Color(0xFFFFEBEE);

/// Colores del semáforo de salud, guardados dentro del ThemeData.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.green,
    required this.greenContainer,
    required this.amber,
    required this.amberContainer,
    required this.red,
    required this.redContainer,
  });

  final Color green;
  final Color greenContainer;
  final Color amber;
  final Color amberContainer;
  final Color red;
  final Color redContainer;

  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>()!;

  @override
  StatusColors copyWith({
    Color? green,
    Color? greenContainer,
    Color? amber,
    Color? amberContainer,
    Color? red,
    Color? redContainer,
  }) {
    return StatusColors(
      green: green ?? this.green,
      greenContainer: greenContainer ?? this.greenContainer,
      amber: amber ?? this.amber,
      amberContainer: amberContainer ?? this.amberContainer,
      red: red ?? this.red,
      redContainer: redContainer ?? this.redContainer,
    );
  }

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      green: Color.lerp(green, other.green, t)!,
      greenContainer: Color.lerp(greenContainer, other.greenContainer, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberContainer: Color.lerp(amberContainer, other.amberContainer, t)!,
      red: Color.lerp(red, other.red, t)!,
      redContainer: Color.lerp(redContainer, other.redContainer, t)!,
    );
  }
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
      error: _red,
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
      extensions: const [
        StatusColors(
          green: _green,
          greenContainer: _greenContainer,
          amber: _amber,
          amberContainer: _amberContainer,
          red: _red,
          redContainer: _redContainer,
        ),
      ],
    );
  }
}
