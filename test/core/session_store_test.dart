import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('valores por defecto', () async {
    final store = await SessionStore.create();

    expect(store.hasSession, isFalse);
    expect(store.termsAccepted, isFalse);
    expect(store.dailyTipNotifications, isTrue);
    expect(store.alertNotifications, isTrue);
    expect(store.motherPhone, isNull);
  });

  test(
    'clearSession borra la sesión y conserva T&C, toggles y teléfono',
    () async {
      final store = await SessionStore.create();
      await store.saveSession(
        token: 't',
        userId: 'u1',
        fullName: 'Carlos Ruiz',
        email: 'carlos@mail.com',
      );
      await store.setTermsAccepted(true);
      await store.setAlertNotifications(false);
      await store.setMotherPhone(' 987654321 ');

      await store.clearSession();

      expect(store.token, isNull);
      expect(store.fullName, isNull);
      expect(store.termsAccepted, isTrue);
      expect(store.alertNotifications, isFalse);
      expect(store.motherPhone, '987654321');
    },
  );

  test('un teléfono vacío se borra', () async {
    final store = await SessionStore.create();
    await store.setMotherPhone('987654321');
    await store.setMotherPhone('   ');

    expect(store.motherPhone, isNull);
  });
}
