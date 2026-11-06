import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/api_client.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'core/local_db.dart';
import 'core/session_store.dart';
import 'core/widgets/waking_server_banner.dart';
import 'features/auth/ui/splash_screen.dart';
import 'features/companion/ui/companion_shell.dart';

/// Llave global del navegador: permite volver al login desde fuera de un
/// widget (por ejemplo, cuando el backend responde 401).
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sessionStore = await SessionStore.create();
  final localDb = LocalDb();
  final apiClient = ApiClient(
    sessionStore: sessionStore,
    onUnauthorized: () async {
      await localDb.clear();
      // El Splash decide a dónde ir (sin token, al login).
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.splash,
        (_) => false,
      );
    },
  );

  runApp(
    HelpMomApp(
      sessionStore: sessionStore,
      localDb: localDb,
      apiClient: apiClient,
    ),
  );
}

class HelpMomApp extends StatelessWidget {
  const HelpMomApp({
    super.key,
    required this.sessionStore,
    required this.localDb,
    required this.apiClient,
  });

  final SessionStore sessionStore;
  final LocalDb localDb;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: sessionStore),
        RepositoryProvider.value(value: localDb),
        RepositoryProvider.value(value: apiClient),
      ],
      child: MaterialApp(
        title: 'HelpMom Compañero',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        navigatorKey: navigatorKey,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.home: (_) => const CompanionShell(),
        },
        builder: (context, child) => Stack(
          children: [
            child!,
            WakingServerBanner(isWaking: apiClient.isWakingServer),
          ],
        ),
      ),
    );
  }
}
