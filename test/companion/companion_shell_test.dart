import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/app_theme.dart';
import 'package:helpmom_companion/features/companion/ui/companion_shell.dart';

void main() {
  Widget buildApp() => MaterialApp(
    theme: AppTheme.light(useGoogleFonts: false),
    home: const CompanionShell(),
  );

  void setScreenSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('usa NavigationBar con 600 dp o menos', (tester) async {
    setScreenSize(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

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
}
