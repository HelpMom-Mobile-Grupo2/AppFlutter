import 'package:flutter/material.dart';

import '../../../core/app_routes.dart';

/// P0. Por ahora solo pasa al contenedor principal; en el bloque 3 revisa los
/// T&C, el token y el vínculo familiar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text('HelpMom', style: textTheme.headlineMedium),
            Text('Modo Compañero', style: textTheme.titleMedium),
            const SizedBox(height: 24),
            const CircularProgressIndicator.adaptive(),
          ],
        ),
      ),
    );
  }
}
