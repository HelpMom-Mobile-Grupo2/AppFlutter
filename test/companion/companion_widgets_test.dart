import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/app_theme.dart';
import 'package:helpmom_companion/features/companion/data/companion_summary.dart';
import 'package:helpmom_companion/features/companion/ui/widgets/mission_list.dart';
import 'package:helpmom_companion/features/companion/ui/widgets/status_card.dart';

import '../support/fake_companion_repository.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(useGoogleFonts: false),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  group('StatusCard', () {
    for (final (light, badge, icon) in [
      (HealthLight.green, 'Estable', Icons.check_circle),
      (HealthLight.yellow, 'Atención', Icons.warning_amber_rounded),
      (HealthLight.red, 'Urgente', Icons.error),
    ]) {
      testWidgets('semáforo ${light.label}: ícono de 40 dp y "$badge"', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(
            StatusCard(
              summary: CompanionSummary(
                motherName: 'Daniela',
                gestationalWeeks: 25,
                gestationalDays: 1,
                healthLight: light,
              ),
            ),
          ),
        );

        expect(find.text(badge), findsOneWidget);
        expect(tester.widget<Icon>(find.byIcon(icon)).size, 40);
      });
    }

    testWidgets('sin mediciones no muestra badge', (tester) async {
      await tester.pumpWidget(
        wrap(const StatusCard(summary: CompanionSummary(motherName: 'Dani'))),
      );

      expect(find.text('Estable'), findsNothing);
      expect(find.textContaining('Aún no hay mediciones'), findsOneWidget);
    });
  });

  testWidgets('MissionList: el tip hecho va tachado y con check verde', (
    tester,
  ) async {
    String? toggled;
    await tester.pumpWidget(
      wrap(MissionList(tips: sampleTips, onToggle: (id) => toggled = id)),
    );

    // t3 está hecho.
    final doneText = tester.widget<Text>(
      find.text('Pregúntale cómo se siente'),
    );
    expect(doneText.style?.decoration, TextDecoration.lineThrough);
    final doneTile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Pregúntale cómo se siente'),
    );
    expect(doneTile.value, isTrue);
    expect(doneTile.activeColor, StatusColors.green);

    final pendingText = tester.widget<Text>(
      find.text('Evita que cargue peso o paquetes'),
    );
    expect(pendingText.style?.decoration, isNot(TextDecoration.lineThrough));

    // Tocar el tip hecho lo desmarca.
    await tester.tap(find.text('Pregúntale cómo se siente'));
    expect(toggled, 't3');
  });
}
