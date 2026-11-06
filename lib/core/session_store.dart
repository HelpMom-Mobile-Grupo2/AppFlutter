import 'package:shared_preferences/shared_preferences.dart';

/// Datos pequeños del dispositivo en shared_preferences: la sesión, la
/// aceptación de los T&C, los toggles de notificaciones y el teléfono de la
/// madre.
class SessionStore {
  SessionStore(this._prefs);

  static Future<SessionStore> create() async =>
      SessionStore(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _tokenKey = 'token';
  static const _userIdKey = 'user_id';
  static const _fullNameKey = 'full_name';
  static const _emailKey = 'email';
  static const _termsKey = 'terms_accepted';
  static const _dailyTipKey = 'notify_daily_tip';
  static const _alertsKey = 'notify_alerts';
  static const _motherPhoneKey = 'mother_phone';

  // Sesión

  String? get token => _prefs.getString(_tokenKey);
  bool get hasSession => token != null;
  String? get userId => _prefs.getString(_userIdKey);
  String? get fullName => _prefs.getString(_fullNameKey);
  String? get email => _prefs.getString(_emailKey);

  Future<void> saveSession({
    required String token,
    required String userId,
    required String fullName,
    required String email,
  }) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userIdKey, userId);
    await _prefs.setString(_fullNameKey, fullName);
    await _prefs.setString(_emailKey, email);
  }

  /// Borra solo la sesión. Los T&C, los toggles y el teléfono se conservan,
  /// porque el token vence cada 60 minutos.
  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_fullNameKey);
    await _prefs.remove(_emailKey);
  }

  // Términos y condiciones

  bool get termsAccepted => _prefs.getBool(_termsKey) ?? false;

  Future<void> setTermsAccepted(bool accepted) =>
      _prefs.setBool(_termsKey, accepted);

  // Preferencias de notificaciones

  bool get dailyTipNotifications => _prefs.getBool(_dailyTipKey) ?? true;

  Future<void> setDailyTipNotifications(bool enabled) =>
      _prefs.setBool(_dailyTipKey, enabled);

  bool get alertNotifications => _prefs.getBool(_alertsKey) ?? true;

  Future<void> setAlertNotifications(bool enabled) =>
      _prefs.setBool(_alertsKey, enabled);

  // Teléfono de la madre (el backend no lo guarda)

  String? get motherPhone => _prefs.getString(_motherPhoneKey);

  Future<void> setMotherPhone(String? phone) async {
    final value = phone?.trim() ?? '';
    if (value.isEmpty) {
      await _prefs.remove(_motherPhoneKey);
    } else {
      await _prefs.setString(_motherPhoneKey, value);
    }
  }
}
