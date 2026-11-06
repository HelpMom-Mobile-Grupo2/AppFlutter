import 'package:flutter/material.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'features/auth/ui/splash_screen.dart';
import 'features/companion/ui/companion_shell.dart';

/// Llave global del navegador: permite volver al login desde fuera de un
/// widget (por ejemplo, cuando el backend responde 401).
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const HelpMomApp());
}

class HelpMomApp extends StatelessWidget {
  const HelpMomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelpMom Compañero',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      navigatorKey: navigatorKey,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.home: (_) => const CompanionShell(),
      },
    );
  }
}
