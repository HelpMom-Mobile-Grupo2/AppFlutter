import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/api_client.dart';
import 'package:helpmom_companion/core/app_routes.dart';
import 'package:helpmom_companion/core/app_theme.dart';
import 'package:helpmom_companion/core/local_db.dart';
import 'package:helpmom_companion/core/session_store.dart';
import 'package:helpmom_companion/features/auth/bloc/auth_bloc.dart';
import 'package:helpmom_companion/features/auth/data/auth_api.dart';
import 'package:helpmom_companion/features/auth/data/auth_repository.dart';
import 'package:helpmom_companion/features/auth/ui/terms_screen.dart';
import 'package:helpmom_companion/features/family/data/family_api.dart';
import 'package:helpmom_companion/features/family/data/family_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SessionStore session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = await SessionStore.create();
  });

  Widget buildApp({bool readOnly = false}) {
    final client = ApiClient(
      sessionStore: session,
      httpClient: MockClient((_) async => http.Response('', 500)),
      baseUrl: 'https://api.test/',
    );
    return BlocProvider(
      create: (_) => AuthBloc(
        authRepository: AuthRepository(
          api: AuthApi(client),
          session: session,
          localDb: LocalDb(),
        ),
        familyRepository: FamilyRepository(api: FamilyApi(client)),
      ),
      child: MaterialApp(
        theme: AppTheme.light(useGoogleFonts: false),
        home: TermsScreen(readOnly: readOnly),
        routes: {AppRoutes.login: (_) => const Text('Pantalla de login')},
      ),
    );
  }

  FilledButton acceptButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Aceptar y continuar'),
  );

  testWidgets('el botón se habilita solo al marcar "Leí y acepto"', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    expect(acceptButton(tester).onPressed, isNull);

    await tester.tap(find.text('Leí y acepto los Términos y condiciones'));
    await tester.pump();

    expect(acceptButton(tester).onPressed, isNotNull);
  });

  testWidgets('al aceptar guarda los T&C y va al login', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Leí y acepto los Términos y condiciones'));
    await tester.pump();
    await tester.tap(find.text('Aceptar y continuar'));
    await tester.pumpAndSettle();

    expect(session.termsAccepted, isTrue);
    expect(find.text('Pantalla de login'), findsOneWidget);
  });

  testWidgets('en modo lectura no pide aceptación', (tester) async {
    await tester.pumpWidget(buildApp(readOnly: true));

    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('Aceptar y continuar'), findsNothing);
  });
}
