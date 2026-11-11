import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/api_exception.dart';
import 'package:helpmom_companion/core/app_routes.dart';
import 'package:helpmom_companion/core/app_theme.dart';
import 'package:helpmom_companion/core/session_store.dart';
import 'package:helpmom_companion/features/alerts/bloc/alerts_bloc.dart';
import 'package:helpmom_companion/features/alerts/data/alert_model.dart';
import 'package:helpmom_companion/features/alerts/ui/sos_dialog.dart';
import 'package:helpmom_companion/features/auth/bloc/auth_bloc.dart';
import 'package:helpmom_companion/features/companion/cubit/summary_cubit.dart';
import 'package:helpmom_companion/features/companion/cubit/tips_cubit.dart';
import 'package:helpmom_companion/features/companion/data/companion_summary.dart';
import 'package:helpmom_companion/features/companion/ui/companion_shell.dart';
import 'package:helpmom_companion/features/family/data/family_repository.dart';
import 'package:helpmom_companion/features/profile/cubit/profile_cubit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_alerts_repository.dart';
import '../support/fake_auth_repository.dart';
import '../support/fake_companion_repository.dart';
import '../support/fake_family_repository.dart';

void main() {
  late SessionStore session;
  late FakeAlertsRepository alertsRepository;
  late FakeCompanionRepository companionRepository;

  // Las alertas de prueba tienen más de un día y se muestran con fecha.
  setUpAll(() => initializeDateFormatting('es'));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = await SessionStore.create();
    await session.saveSession(
      token: 't',
      userId: 'u1',
      fullName: 'Carlos Ruiz',
      email: 'carlos@mail.com',
    );
    alertsRepository = FakeAlertsRepository(alerts: [buildAlert()]);
    companionRepository = FakeCompanionRepository();
  });

  Widget buildApp({Duration refreshInterval = const Duration(seconds: 15)}) {
    final familyRepository = FakeFamilyRepository();
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: session),
        RepositoryProvider<FamilyRepository>.value(value: familyRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(
              authRepository: FakeAuthRepository(session),
              familyRepository: familyRepository,
            ),
          ),
          BlocProvider(
            create: (_) => AlertsBloc(alertsRepository: alertsRepository),
          ),
          BlocProvider(
            create: (_) => SummaryCubit(companionRepository)..load(),
          ),
          BlocProvider(create: (_) => TipsCubit(companionRepository)..load()),
          BlocProvider(create: (_) => ProfileCubit(session)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: CompanionShell(refreshInterval: refreshInterval),
          routes: {AppRoutes.link: (_) => const Text('Pantalla Vincular')},
        ),
      ),
    );
  }

  void setScreenSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('usa NavigationBar con 600 dp o menos', (tester) async {
    setScreenSize(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    for (final icon in [
      Icons.home_rounded,
      Icons.notifications_rounded,
      Icons.menu_book_rounded,
      Icons.person_rounded,
    ]) {
      expect(find.byIcon(icon), findsOneWidget);
    }

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Alertas'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
  });

  testWidgets('usa NavigationRail con más de 600 dp', (tester) async {
    setScreenSize(tester, const Size(1000, 800));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Perfil'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 3);
  });

  testWidgets('Inicio pide pendientes y Alertas pide todas', (tester) async {
    setScreenSize(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(alertsRepository.fetchPendingCalls, 1);
    expect(alertsRepository.fetchAllCalls, 0);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Alertas'),
      ),
    );
    await tester.pumpAndSettle();

    expect(alertsRepository.fetchAllCalls, 1);
  });

  testWidgets('Inicio muestra la alerta activa, el estado y la misión', (
    tester,
  ) async {
    setScreenSize(tester, const Size(400, 2000));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Modo Compañero'), findsOneWidget);
    expect(find.text('Hola, Carlos'), findsOneWidget);
    expect(find.text('C'), findsOneWidget); // Avatar con la inicial.
    expect(find.text('Daniela Gómez (Sem. 25)'), findsOneWidget);
    expect(find.text("⚠ Daniela Gómez pulsó 'Pasa la Voz'"), findsOneWidget);
    expect(find.text('Estado de Daniela Gómez hoy'), findsOneWidget);
    expect(find.text('Semáforo verde'), findsOneWidget);
    expect(find.text('Estable'), findsOneWidget);
    expect(find.text('Semana 25 · Día 1'), findsOneWidget);
    expect(find.text('Misión de apoyo de hoy'), findsOneWidget);
    expect(find.text('Evita que cargue peso o paquetes'), findsOneWidget);
  });

  group('orden de Inicio', () {
    double topOf(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    testWidgets('con alerta pendiente, la alerta va primero', (tester) async {
      setScreenSize(tester, const Size(400, 2000));
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        topOf(tester, "⚠ Daniela Gómez pulsó 'Pasa la Voz'"),
        lessThan(topOf(tester, 'Estado de Daniela Gómez hoy')),
      );
    });

    testWidgets('sin alerta pendiente, el semáforo va primero', (tester) async {
      setScreenSize(tester, const Size(400, 2000));
      alertsRepository.alerts = [];
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(
        topOf(tester, 'Estado de Daniela Gómez hoy'),
        lessThan(
          topOf(
            tester,
            'Aún no hay alertas, te avisaremos cuando Daniela Gómez te '
            'necesite',
          ),
        ),
      );
    });
  });

  testWidgets('estado vacío si no hay embarazo ni mediciones (D.2)', (
    tester,
  ) async {
    setScreenSize(tester, const Size(400, 2000));
    companionRepository.summary = const CompanionSummary(
      motherName: 'Daniela Gómez',
    );
    alertsRepository.alerts = [];
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aún no hay alertas, te avisaremos cuando Daniela Gómez te necesite',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Aún no hay mediciones de salud'),
      findsOneWidget,
    );
    expect(
      find.text('Daniela Gómez aún no registró su embarazo.'),
      findsOneWidget,
    );
  });

  testWidgets('409 "no vinculado" lleva a Vincular', (tester) async {
    setScreenSize(tester, const Size(400, 800));
    alertsRepository.fetchError = const NotLinkedException();
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Pantalla Vincular'), findsOneWidget);
  });

  group('SOS nueva', () {
    final sos = buildAlert(
      id: 'sos1',
      type: AlertType.sos,
      message:
          'Alerta automática: el asistente detectó una posible emergencia: '
          'sangrado abundante',
      minutesAgo: 1,
    );

    testWidgets('abre el aviso rojo y "Ya lo vi" lo cierra', (tester) async {
      setScreenSize(tester, const Size(400, 900));
      alertsRepository.alerts = [sos];
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(SosDialog), findsOneWidget);
      expect(find.text('Daniela Gómez necesita ayuda'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SosDialog),
          matching: find.text('Motivo: sangrado abundante'),
        ),
        findsOneWidget,
      );

      // No se cierra tocando afuera ni con "atrás".
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SosDialog), findsOneWidget);

      await tester.tap(find.text('Ya lo vi'));
      await tester.pumpAndSettle();
      expect(find.byType(SosDialog), findsNothing);
      expect(alertsRepository.respondCalls, isEmpty);
    });

    testWidgets('"Voy en camino" responde y cierra el aviso', (tester) async {
      setScreenSize(tester, const Size(400, 900));
      alertsRepository.alerts = [sos];
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(SosDialog),
          matching: find.text('Voy en camino'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SosDialog), findsNothing);
      expect(alertsRepository.respondCalls, [('sos1', AlertResponse.onMyWay)]);
    });

    testWidgets('en Inicio el timer no repite el pedido de alertas', (
      tester,
    ) async {
      setScreenSize(tester, const Size(400, 900));
      await tester.pumpWidget(
        buildApp(refreshInterval: const Duration(seconds: 5)),
      );
      await tester.pumpAndSettle();
      final alertCalls = alertsRepository.fetchPendingCalls;
      final summaryCalls = companionRepository.summaryCalls;

      // 5 s: corre el timer del contenedor, todavía no el polling del bloc
      // (15 s).
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(alertsRepository.fetchPendingCalls, alertCalls);
      expect(companionRepository.summaryCalls, greaterThan(summaryCalls));
    });

    testWidgets('el timer trae la SOS sin deslizar, desde Perfil', (
      tester,
    ) async {
      setScreenSize(tester, const Size(400, 900));
      alertsRepository.alerts = [];
      await tester.pumpWidget(
        buildApp(refreshInterval: const Duration(seconds: 5)),
      );
      await tester.pumpAndSettle();

      // En Perfil no corre el polling del bloc: solo el timer del contenedor.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Perfil'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SosDialog), findsNothing);
      final summaryCalls = companionRepository.summaryCalls;

      alertsRepository.alerts = [sos];
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.byType(SosDialog), findsOneWidget);
      expect(companionRepository.summaryCalls, greaterThan(summaryCalls));

      // Sigue pendiente, pero el aviso no se repite.
      await tester.tap(find.text('Ya lo vi'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(SosDialog), findsNothing);
    });
  });
}
