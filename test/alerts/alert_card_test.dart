import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/app_theme.dart';
import 'package:helpmom_companion/features/alerts/data/alert_model.dart';
import 'package:helpmom_companion/features/alerts/ui/alert_card.dart';

import '../support/fake_alerts_repository.dart';

void main() {
  AlertResponse? answered;
  var calledMother = 0;
  var calledEmergency = 0;

  setUp(() {
    answered = null;
    calledMother = 0;
    calledEmergency = 0;
  });

  Widget buildCard(QuickAlert alert) {
    return MaterialApp(
      theme: AppTheme.light(useGoogleFonts: false),
      home: Scaffold(
        body: SingleChildScrollView(
          child: AlertCard(
            alert: alert,
            motherName: 'Daniela',
            now: baseTime,
            onRespond: (response) => answered = response,
            onCallMother: () => calledMother++,
            onCallEmergency: () => calledEmergency++,
          ),
        ),
      ),
    );
  }

  /// Borde de la tarjeta (color y grosor).
  BorderSide cardSide(WidgetTester tester) {
    final card = tester.widget<Card>(find.byType(Card));
    return (card.shape! as RoundedRectangleBorder).side;
  }

  testWidgets('pendiente → respondida', (tester) async {
    final alert = buildAlert(minutesAgo: 5);
    await tester.pumpWidget(buildCard(alert));

    expect(find.text("⚠ Daniela pulsó 'Pasa la Voz'"), findsOneWidget);
    expect(find.text('Hace 5 min'), findsOneWidget);
    expect(find.textContaining('"Siento mucho cansancio'), findsOneWidget);
    expect(
      tester.widget<Card>(find.byType(Card)).color,
      AppColors.alertContainer,
    );
    expect(cardSide(tester).color, AppColors.alertBorder);
    expect(cardSide(tester).width, 1.5);
    expect(find.widgetWithText(FilledButton, 'Voy en camino'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Llamando ahora'),
      findsOneWidget,
    );
    expect(find.text('Ya me encargué'), findsOneWidget);
    expect(find.text('Llamar al 106 (SAMU)'), findsNothing);

    await tester.tap(find.text('Llamando ahora'));
    expect(answered, AlertResponse.callingNow);
    await tester.tap(find.text('Ya me encargué'));
    expect(answered, AlertResponse.done);
    await tester.tap(find.text('Voy en camino'));
    expect(answered, AlertResponse.onMyWay);

    // El bloc devuelve la alerta respondida: la tarjeta pasa a verde.
    await tester.pumpWidget(
      buildCard(alert.respondedWith(AlertResponse.onMyWay, baseTime)),
    );

    expect(find.text('✓ Solicitud confirmada'), findsOneWidget);
    expect(find.text('Respondiste: Voy en camino'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Voy en camino'), findsNothing);
    expect(cardSide(tester).color, StatusColors.green);
    final done = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Respondido ✓'),
    );
    expect(done.onPressed, isNull);
  });

  testWidgets('SOS: tarjeta roja con el motivo y tres acciones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildCard(
        buildAlert(
          type: AlertType.sos,
          message: 'Alerta automática: la medición de salud salió en rojo',
          minutesAgo: 1,
        ),
      ),
    );

    expect(find.text('🆘 SOS de Daniela'), findsOneWidget);
    expect(tester.widget<Card>(find.byType(Card)).color, StatusColors.red);
    expect(find.text('Motivo: Medición de salud en rojo'), findsOneWidget);
    // El motivo reemplaza al mensaje entre comillas.
    expect(find.textContaining('"Alerta automática'), findsNothing);
    expect(find.text('Voy en camino'), findsOneWidget);
    expect(find.text('Llamar a Daniela'), findsOneWidget);
    expect(find.text('Llamar al 106 (SAMU)'), findsOneWidget);
    expect(find.text('Te llamo ahora'), findsNothing);
    expect(find.text('Ya me encargué'), findsNothing);

    await tester.tap(find.text('Llamar a Daniela'));
    await tester.tap(find.text('Llamar al 106 (SAMU)'));
    await tester.tap(find.text('Voy en camino'));

    expect(calledMother, 1);
    expect(calledEmergency, 1);
    expect(answered, AlertResponse.onMyWay);
  });

  testWidgets('SOS enviada a mano: sin motivo, con su mensaje', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildCard(
        buildAlert(
          type: AlertType.sos,
          message: 'Necesito ayuda urgente. Comunícate conmigo ahora.',
        ),
      ),
    );

    expect(find.textContaining('Motivo:'), findsNothing);
    expect(find.textContaining('"Necesito ayuda urgente'), findsOneWidget);
  });

  testWidgets('SOS respondida sigue mostrando las llamadas', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildCard(
        buildAlert(
          type: AlertType.sos,
          status: AlertStatus.responded,
          response: AlertResponse.onMyWay,
        ),
      ),
    );

    expect(find.text('✓ Solicitud confirmada'), findsOneWidget);
    expect(find.text('Respondido ✓'), findsOneWidget);
    expect(find.text('Llamar a Daniela'), findsOneWidget);
    expect(find.text('Llamar al 106 (SAMU)'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Voy en camino'), findsNothing);
  });
}
