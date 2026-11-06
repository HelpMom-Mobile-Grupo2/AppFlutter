import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/app_theme.dart';
import 'package:helpmom_companion/features/companion/cubit/summary_cubit.dart';
import 'package:helpmom_companion/features/companion/cubit/tips_cubit.dart';
import 'package:helpmom_companion/features/companion/data/companion_summary.dart';
import 'package:helpmom_companion/features/companion/data/weekly_guide.dart';
import 'package:helpmom_companion/features/companion/ui/guide_screen.dart';

import '../support/fake_companion_repository.dart';

void main() {
  late FakeCompanionRepository repository;

  setUp(() {
    repository = FakeCompanionRepository();
    // rootBundle guarda en caché el Future de la lectura, creado con el reloj
    // falso del test anterior: lo vaciamos para leer el JSON de nuevo.
    rootBundle.evict(WeeklyGuide.assetPath);
  });

  Future<void> pumpGuide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SummaryCubit(repository)..load()),
          BlocProvider(create: (_) => TipsCubit(repository)..load()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(useGoogleFonts: false),
          home: const GuideScreen(),
        ),
      ),
    );
    // El JSON se lee del disco con tiempo real, no con el reloj falso del
    // test: dejamos correr el tiempo real hasta que aparece la ilustración.
    for (var i = 0; i < 100 && find.byType(Image).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los tips con su texto y el check "Hecho"', (
    tester,
  ) async {
    await pumpGuide(tester);

    expect(find.text('¿Cómo ayudar hoy?'), findsOneWidget);
    expect(find.text('Evita que cargue peso o paquetes'), findsOneWidget);
    expect(find.text('Desde el segundo trimestre...'), findsOneWidget);
    expect(find.text('Hecho'), findsNWidgets(3));

    await tester.tap(find.text('Evita que cargue peso o paquetes'));
    await tester.pump();

    final tile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Evita que cargue peso o paquetes'),
    );
    expect(tile.value, isTrue);
    expect(repository.tips.first.done, isTrue);
  });

  testWidgets('muestra la guía de la semana actual con su ilustración', (
    tester,
  ) async {
    await pumpGuide(tester);

    expect(find.text('Semana 25 · esta semana'), findsOneWidget);
    expect(
      find.textContaining('Es del tamaño de una coliflor.'),
      findsOneWidget,
    );
    expect(find.text('Cambios en Daniela Gómez'), findsOneWidget);
    expect(find.text('Preparativos'), findsOneWidget);

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/trimester_2.png',
    );
    expect(image.fit, BoxFit.cover);
  });

  testWidgets('las flechas cambian de semana y se puede volver', (
    tester,
  ) async {
    await pumpGuide(tester);

    await tester.tap(find.byTooltip('Semana siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Semana 26'), findsOneWidget);
    expect(
      find.textContaining('Es del tamaño de una lechuga.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Volver a esta semana'));
    await tester.pumpAndSettle();
    expect(find.text('Semana 25 · esta semana'), findsOneWidget);
  });

  testWidgets('sin embarazo registrado avisa y empieza en la semana 4', (
    tester,
  ) async {
    repository.summary = const CompanionSummary(motherName: 'Daniela Gómez');
    await pumpGuide(tester);

    expect(
      find.textContaining('Daniela Gómez aún no registró su embarazo'),
      findsOneWidget,
    );
    expect(find.text('Semana 4'), findsOneWidget);
  });
}
