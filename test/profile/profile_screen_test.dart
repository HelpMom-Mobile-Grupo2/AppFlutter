import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/api_exception.dart';
import 'package:helpmom_companion/core/app_routes.dart';
import 'package:helpmom_companion/core/app_theme.dart';
import 'package:helpmom_companion/core/session_store.dart';
import 'package:helpmom_companion/features/auth/bloc/auth_bloc.dart';
import 'package:helpmom_companion/features/family/data/family_repository.dart';
import 'package:helpmom_companion/features/profile/cubit/profile_cubit.dart';
import 'package:helpmom_companion/features/profile/ui/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_family_repository.dart';

void main() {
  late SessionStore session;
  late FakeFamilyRepository familyRepository;
  late FakeAuthRepository authRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = await SessionStore.create();
    await session.saveSession(
      token: 't',
      userId: 'u1',
      fullName: 'Carlos Ruiz',
      email: 'carlos@mail.com',
    );
    familyRepository = FakeFamilyRepository();
    authRepository = FakeAuthRepository(session);
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepositoryProvider<FamilyRepository>.value(
        value: familyRepository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AuthBloc(
                authRepository: authRepository,
                familyRepository: familyRepository,
              ),
            ),
            BlocProvider(create: (_) => ProfileCubit(session)),
          ],
          child: MaterialApp(
            theme: AppTheme.light(useGoogleFonts: false),
            home: const ProfileScreen(),
            routes: {
              AppRoutes.login: (_) => const Text('Pantalla de login'),
              AppRoutes.terms: (context) => Text(
                'T&C solo lectura: '
                '${ModalRoute.of(context)?.settings.arguments}',
              ),
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra nombre, correo y a quién acompaña', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Carlos Ruiz'), findsOneWidget);
    expect(find.text('carlos@mail.com'), findsOneWidget);
    expect(find.text('Acompañando a Daniela Gómez'), findsOneWidget);
    expect(find.text('Teléfono de Daniela Gómez'), findsOneWidget);
  });

  testWidgets('sin conexión ofrece reintentar', (tester) async {
    familyRepository.error = const NoConnectionException();
    await pumpProfile(tester);

    expect(
      find.text('Sin conexión: no pudimos ver a quién acompañas.'),
      findsOneWidget,
    );

    familyRepository.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Acompañando a Daniela Gómez'), findsOneWidget);
  });

  testWidgets('los toggles se guardan en shared_preferences', (tester) async {
    await pumpProfile(tester);

    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));

    await tester.tap(find.text('Tip del día'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();

    expect(session.dailyTipNotifications, isFalse);
    expect(session.alertNotifications, isFalse);
  });

  testWidgets('guarda y borra el teléfono de la madre', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Teléfono de Daniela Gómez'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Revisa el número.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '987 654 321');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(session.motherPhone, '987 654 321');
    expect(find.text('987 654 321'), findsOneWidget);

    await tester.tap(find.text('Teléfono de Daniela Gómez'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(session.motherPhone, isNull);
  });

  testWidgets('abre los T&C en modo solo lectura', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.text('Términos y condiciones'));
    await tester.pumpAndSettle();

    expect(find.text('T&C solo lectura: true'), findsOneWidget);
  });

  testWidgets('cerrar sesión pide confirmación, borra y va al login', (
    tester,
  ) async {
    await session.setMotherPhone('987654321');
    await pumpProfile(tester);

    await tester.tap(find.widgetWithText(ListTile, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(authRepository.logoutCalls, 1);
    expect(session.hasSession, isFalse);
    expect(session.motherPhone, isNull);
    expect(find.text('Pantalla de login'), findsOneWidget);
  });
}
