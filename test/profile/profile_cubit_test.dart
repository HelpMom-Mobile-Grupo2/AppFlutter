import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/session_store.dart';
import 'package:helpmom_companion/features/profile/cubit/profile_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SessionStore session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    session = await SessionStore.create();
    await session.saveSession(
      token: 't',
      userId: 'u1',
      fullName: 'Carlos Ruiz',
      email: 'carlos@mail.com',
    );
  });

  test('empieza con lo guardado en la sesión', () {
    final cubit = ProfileCubit(session);
    addTearDown(cubit.close);

    expect(
      cubit.state,
      const ProfileState(
        fullName: 'Carlos Ruiz',
        email: 'carlos@mail.com',
        dailyTipNotifications: true,
        alertNotifications: true,
      ),
    );
  });

  test('guarda los toggles y el teléfono', () async {
    final cubit = ProfileCubit(session);
    addTearDown(cubit.close);

    await cubit.setDailyTipNotifications(false);
    await cubit.setAlertNotifications(false);
    await cubit.setMotherPhone('987654321');

    expect(cubit.state.dailyTipNotifications, isFalse);
    expect(cubit.state.alertNotifications, isFalse);
    expect(cubit.state.motherPhone, '987654321');
    expect(session.alertNotifications, isFalse);

    await cubit.setMotherPhone('');
    expect(cubit.state.motherPhone, isNull);
  });
}
