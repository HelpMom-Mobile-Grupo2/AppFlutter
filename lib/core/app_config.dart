/// Configuración que llega al compilar con --dart-define.
class AppConfig {
  AppConfig._();

  /// URL del backend. Por defecto, Render. Para el backend local:
  /// flutter run --dart-define=BASE_URL=http://10.0.2.2:61614/
  static const baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://helpmom-backend.onrender.com/',
  );
}
