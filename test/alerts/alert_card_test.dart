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

  testWidgets('pendiente → respondida', (tester) async {
    final alert = buildAlert(minutesAgo: 5);
    await tester.pumpWidget(buildCard(alert));

    expect(find.text("🔔 Daniela pulsó 'Pasa la Voz'"), findsOneWidget);
    expect(find.text('Cansancio o dolor · hace 5 min'), findsOneWidget);
    expect(find.textContaining('"Siento mucho cansancio'), findsOneWidget);
    expect(find.text('Voy en camino'), findsOneWidget);
    expect(find.text('Te llamo ahora'), findsOneWidget);
    expect(find.text('Ya me encargué'), findsOneWidget);
    expect(find.text('Llamar al 106'), findsNothing);

    await tester.tap(find.text('Voy en camino'));
    expect(answered, AlertResponse.onMyWay);

    // El bloc devuelve la alerta respondida: la tarjeta pasa a verde.
    await tester.pumpWidget(
      buildCard(alert.respondedWith(AlertResponse.onMyWay, baseTime)),
    );

    expect(find.text('✓ Solicitud confirmada · Respondido'), findsOneWidget);
    expect(find.text('Respondiste: Voy en camino'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Voy en camino'), findsNothing);
    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, StatusColors.greenContainer);
  });

  testWidgets('SOS: tarjeta roja con llamadas y respuestas', (tester) async {
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
    expect(find.text('Llamar a Daniela'), findsOneWidget);
    expect(find.text('Llamar al 106'), findsOneWidget);
    expect(find.text('Voy en camino'), findsOneWidget);

    await tester.tap(find.text('Llamar a Daniela'));
    await tester.tap(find.text('Llamar al 106'));
    await tester.tap(find.text('Te llamo ahora'));

    expect(calledMother, 1);
    expect(calledEmergency, 1);
    expect(answered, AlertResponse.callingNow);
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

    expect(find.text('✓ Solicitud confirmada · Respondido'), findsOneWidget);
    expect(find.text('Llamar a Daniela'), findsOneWidget);
    expect(find.text('Llamar al 106'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Voy en camino'), findsNothing);
  });
}
