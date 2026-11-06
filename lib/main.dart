import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/api_client.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'core/local_db.dart';
import 'core/session_store.dart';
import 'core/widgets/waking_server_banner.dart';
import 'features/alerts/bloc/alerts_bloc.dart';
import 'features/alerts/data/alerts_api.dart';
import 'features/alerts/data/alerts_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/auth/ui/splash_screen.dart';
import 'features/auth/ui/terms_screen.dart';
import 'features/companion/cubit/summary_cubit.dart';
import 'features/companion/cubit/tips_cubit.dart';
import 'features/companion/data/companion_api.dart';
import 'features/companion/data/companion_repository.dart';
import 'features/companion/ui/companion_shell.dart';
import 'features/family/cubit/link_cubit.dart';
import 'features/family/data/family_api.dart';
import 'features/family/data/family_repository.dart';
import 'features/family/ui/link_screen.dart';
import 'features/family/ui/scanner_screen.dart';

/// Llave global del navegador: permite volver al login desde fuera de un
/// widget (por ejemplo, cuando el backend responde 401).
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nombres de meses en español para intl ("3 nov, 20:10").
  await initializeDateFormatting('es');

  final sessionStore = await SessionStore.create();
  final localDb = LocalDb();
  final apiClient = ApiClient(
    sessionStore: sessionStore,
    onUnauthorized: () async {
      await localDb.clear();
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
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
        RepositoryProvider(
          create: (_) => AuthRepository(
            api: AuthApi(apiClient),
            session: sessionStore,
            localDb: localDb,
          ),
        ),
        RepositoryProvider(
          create: (_) => FamilyRepository(api: FamilyApi(apiClient)),
        ),
        RepositoryProvider(
          create: (_) => CompanionRepository(
            api: CompanionApi(apiClient),
            localDb: localDb,
          ),
        ),
        RepositoryProvider(
          create: (_) =>
              AlertsRepository(api: AlertsApi(apiClient), localDb: localDb),
        ),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
          familyRepository: context.read<FamilyRepository>(),
        ),
        child: MaterialApp(
          title: 'HelpMom Compañero',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          navigatorKey: navigatorKey,
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.terms: (context) => TermsScreen(
              // Desde Perfil se abre con `arguments: true` (solo lectura).
              readOnly: ModalRoute.of(context)?.settings.arguments == true,
            ),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.link: (context) => BlocProvider(
              create: (context) => LinkCubit(context.read<FamilyRepository>()),
              child: const LinkScreen(),
            ),
            AppRoutes.scanner: (_) => const ScannerScreen(),
            // Inicio y Alertas comparten el mismo AlertsBloc; Inicio y Guía,
            // el mismo TipsCubit.
            AppRoutes.home: (context) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => AlertsBloc(
                    alertsRepository: context.read<AlertsRepository>(),
                    pollingEnabled: () => sessionStore.alertNotifications,
                  ),
                ),
                BlocProvider(
                  create: (context) =>
                      SummaryCubit(context.read<CompanionRepository>())..load(),
                ),
                BlocProvider(
                  create: (context) =>
                      TipsCubit(context.read<CompanionRepository>())..load(),
                ),
              ],
              child: const CompanionShell(),
            ),
          },
          builder: (context, child) => Stack(
            children: [
              child!,
              WakingServerBanner(isWaking: apiClient.isWakingServer),
            ],
          ),
        ),
      ),
    );
  }
}
