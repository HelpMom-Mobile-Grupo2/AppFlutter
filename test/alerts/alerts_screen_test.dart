import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/api_exception.dart';
import 'package:helpmom_companion/core/app_theme.dart';
import 'package:helpmom_companion/core/session_store.dart';
import 'package:helpmom_companion/features/alerts/bloc/alerts_bloc.dart';
import 'package:helpmom_companion/features/alerts/data/alert_model.dart';
import 'package:helpmom_companion/features/alerts/ui/alerts_screen.dart';
import 'package:helpmom_companion/features/companion/cubit/summary_cubit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_alerts_repository.dart';
import '../support/fake_companion_repository.dart';

void main() {
  late SessionStore session;
  late FakeAlertsRepository repository;

  final newPending = buildAlert(
    id: 'p1',
    type: AlertType.craving,
    message: 'Tengo un antojo de mango',
    minutesAgo: 3,
  );
  final oldResponded = buildAlert(
    id: 'r1',
    message: 'Ayúdame con la cena',
    minutesAgo: 90,
    status: AlertStatus.responded,
    response: AlertResponse.done,
  );

  // Las filas muestran fechas con intl en español.
  setUpAll(() => initializeDateFormatting('es'));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = await SessionStore.create();
    // Llega primero la respondida: la pantalla igual pone arriba la pendiente.
    repository = FakeAlertsRepository(alerts: [oldResponded, newPending]);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepositoryProvider.value(
        value: session,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  AlertsBloc(alertsRepository: repository)
                    ..add(const AlertsVisibilityChanged(AlertsView.inbox)),
            ),
            BlocProvider(
              create: (_) => SummaryCubit(FakeCompanionRepository())..load(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(useGoogleFonts: false),
            home: const AlertsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double topOf(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  testWidgets('pendientes arriba y luego el historial', (tester) async {
    await pumpScreen(tester);

    expect(
      topOf(tester, 'Pendientes'),
      lessThan(topOf(tester, newPending.message)),
    );
    expect(
      topOf(tester, newPending.message),
      lessThan(topOf(tester, 'Historial')),
    );
    expect(
      topOf(tester, 'Historial'),
      lessThan(topOf(tester, oldResponded.message)),
    );

    // Cada fila: tipo, estado y respuesta dada.
    expect(find.textContaining('Antojo · '), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Respondida · Ya me encargué'), findsOneWidget);
  });

  testWidgets('sin internet muestra lo guardado con el aviso', (tester) async {
    repository
      ..fetchError = const NoConnectionException()
      ..cached = [newPending, oldResponded];
    await pumpScreen(tester);

    expect(
      find.text('Sin conexión · mostrando lo último guardado'),
      findsOneWidget,
    );
    expect(find.text(newPending.message), findsOneWidget);
  });

  testWidgets('sin internet y sin caché muestra "Reintentar"', (tester) async {
    repository.fetchError = const NoConnectionException();
    await pumpScreen(tester);

    expect(find.textContaining('Sin conexión a internet'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('estado vacío con el nombre de la madre', (tester) async {
    repository.alerts = [];
    await pumpScreen(tester);

    expect(
      find.text(
        'Aún no hay alertas, te avisaremos cuando Daniela Gómez te necesite',
      ),
      findsOneWidget,
    );
  });

  testWidgets('error del servidor con "Reintentar"', (tester) async {
    repository.fetchError = const ApiException(
      statusCode: 500,
      message: 'El servidor tuvo un problema. Intenta más tarde.',
    );
    await pumpScreen(tester);

    expect(
      find.text('El servidor tuvo un problema. Intenta más tarde.'),
      findsOneWidget,
    );

    repository.fetchError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text(newPending.message), findsWidgets);
  });

  testWidgets('se responde una pendiente desde la bandeja', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Responder'));
    await tester.pumpAndSettle();

    expect(find.text("🔔 Daniela Gómez pulsó 'Pasa la Voz'"), findsOneWidget);

    await tester.tap(find.text('Voy en camino'));
    await tester.pumpAndSettle();

    expect(repository.respondCalls, [('p1', AlertResponse.onMyWay)]);
    expect(find.text('✓ Solicitud confirmada · Respondido'), findsOneWidget);
    expect(find.text('Respondida · Voy en camino'), findsOneWidget);
  });

  testWidgets('"Te llamo ahora" con teléfono guardado registra la respuesta', (
    tester,
  ) async {
    await session.setMotherPhone('987654321');
    await pumpScreen(tester);

    await tester.tap(find.text('Responder'));
    await tester.pumpAndSettle();
    // También intenta abrir el marcador (tel:987654321); en los tests no hay
    // plataforma, así que solo verificamos la respuesta.
    await tester.tap(find.text('Te llamo ahora'));
    await tester.pumpAndSettle();

    expect(repository.respondCalls, [('p1', AlertResponse.callingNow)]);
  });
}
