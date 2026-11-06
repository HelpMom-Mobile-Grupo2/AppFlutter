# HelpMom – Modo Compañero (Flutter)

App del **acompañante** de HelpMom para Android e iOS. Muestra el estado resumido de la gestante (semáforo y semana, **sin valores clínicos**), recibe las alertas "Pasa la Voz" y la SOS, propone una misión de apoyo diaria y explica cada semana del embarazo.

Proyecto del curso "Aplicaciones para dispositivos móviles" (UPC). Contrato de la API: [`docs/00_contrato_api_backend.md`](docs/00_contrato_api_backend.md).

## Requisitos

- Flutter estable (probado con 3.47.7 / Dart 3.13.5).
- En Windows hay que activar el **Modo desarrollador** (lo necesitan los plugins).
- Un emulador Android, un simulador iOS o un teléfono.

```bash
flutter pub get
flutter analyze
flutter test
```

## Cómo correrla

### Contra Render (por defecto)

```bash
flutter run
```

La URL por defecto es `https://helpmom-backend.onrender.com/`. Render usa el plan gratis y "se duerme": la primera llamada puede tardar hasta unos 50 s. Mientras tanto, la app muestra **"Conectando con el servidor…"**. El timeout es de 60 s.

### Contra el backend local

1. Levanta el backend (repo `HelpMom-Backend`, PowerShell):
   ```powershell
   dotnet run --project src/BackendMoviles.Api/BackendMoviles.Api.csproj --launch-profile http
   ```
2. Corre la app con la URL según el dispositivo:

   | Dispositivo | Comando |
   |---|---|
   | Emulador Android | `flutter run --dart-define=BASE_URL=http://10.0.2.2:61614/` |
   | Simulador iOS | `flutter run --dart-define=BASE_URL=http://localhost:61614/` |
   | Teléfono físico | `flutter run --dart-define=BASE_URL=http://<IP-de-tu-PC>:61614/` |

   El tráfico HTTP sin cifrar solo está permitido en **debug**: en Android con `src/debug/AndroidManifest.xml`, y en iOS con una excepción ATS solo para `localhost`. Con un teléfono físico, el firewall de la PC tiene que dejar pasar el puerto 61614.

## Probar el flujo completo con la app de la madre

Necesitas la app HelpMom de la madre (Android nativo) apuntando al **mismo backend**. Si todavía no la tienes, cada paso de la madre se puede hacer desde Swagger (`/swagger`) con un token de una cuenta `Mother`: el endpoint va entre paréntesis.

1. **Madre: crea su cuenta y su embarazo.** Se registra (`POST /api/auth/register` con rol `Mother`) y configura su embarazo (`POST /api/pregnancy`).
2. **Acompañante: se registra.** Abre esta app, acepta los **Términos y condiciones** y, en la pestaña **Crear cuenta**, ingresa nombre, correo y una contraseña de 10 a 128 caracteres. Llega a **Vincular con tu pareja**.
3. **Madre: genera el código.** Genera su invitación (`POST /api/family/invitations`), que muestra un QR y una clave `HM-XXXX` válida por 24 h.
4. **Acompañante: se vincula.** Pulsa **Escanear código QR** o escribe la clave, y ve "¡Listo! Ahora acompañas a {nombre}". Luego, **Continuar** lleva a Inicio.
5. **Madre: pulsa "Pasa la Voz".** Envía una alerta (`POST /api/alerts` con `{ "type": 2, "message": "..." }`).
6. **Acompañante: responde.** Con **Inicio** o **Alertas** abiertas, la alerta aparece en 15 s como máximo (o al hacer pull-to-refresh). Pulsa **Voy en camino**: la tarjeta pasa a verde, "✓ Solicitud confirmada · Respondido", y la madre ve la respuesta. **Te llamo ahora** además abre el marcador si guardaste su teléfono en Perfil.
7. **SOS automática.** La madre registra una medición en rojo (`POST /api/telemetry` con, por ejemplo, `{ "fetalHeartRateBpm": 190, "temperatureCelsius": 36.8 }`). El backend crea una alerta SOS y, en Inicio, el acompañante ve la **tarjeta roja** con **Llamar a {nombre}**, **Llamar al 106** y los botones de respuesta. Un mensaje de triage de emergencia de la madre (por ejemplo, "no siento al bebé") también genera una SOS.
8. **Resumen.** En Inicio, la tarjeta **Estado de {nombre} hoy** muestra el semáforo (ahora rojo), el mensaje del backend y "Semana X · Día Y", sin números clínicos. Si la madre aún no tiene embarazo ni mediciones, aparece un estado vacío.
9. **Sin conexión.** Con el modo avión activado, **Alertas** muestra lo último guardado con el aviso "Sin conexión · mostrando lo último guardado", y la misión del día también sale de sqflite.
10. **Desvinculación.** Si la madre desvincula al acompañante (`DELETE /api/family/partner`), la siguiente consulta devuelve 409 "Aún no estás vinculado…" y la app vuelve a **Vincular**.

## Estructura

```
lib/
  main.dart                 MaterialApp, rutas con nombre, tema y providers
  core/                     ApiClient, excepciones, SessionStore, LocalDb (sqflite), tema,
                            fechas, teléfono y widgets de estado (cargando, vacío, error,
                            sin conexión)
  features/
    auth/      data · bloc (AuthBloc) · ui (splash, login/registro, T&C)
    family/    data · cubit (LinkCubit) · ui (vincular, escáner QR)
    companion/ data · cubit (SummaryCubit, TipsCubit) · ui (contenedor, Inicio, Guía)
    alerts/    data (caché sqflite) · bloc (AlertsBloc) · ui (bandeja, tarjeta, fila)
    profile/   cubit (ProfileCubit) · ui (perfil)
assets/   weekly_guide.json (semanas 4 a 41) e ilustraciones por trimestre
test/     modelos, blocs, pantallas y repositorios de prueba (test/support)
```

## Checklist final de requisitos

| # | Requisito | Tema del curso | Estado |
|---|---|---|---|
| 1 | `StatelessWidget` para lo que solo muestra datos y `StatefulWidget` para formularios, checks y escáner. Uso de `Scaffold`, `Column`, `Row`, `Container`, `Card`, `ListTile`, `Icon` e `Image` | Widgets | ✅ |
| 2 | `MaterialApp` con rutas con nombre (`pushNamed`, `pushReplacementNamed`) y `GlobalKey<NavigatorState>` | Rutas | ✅ |
| 3 | 4 pestañas en un `Scaffold` con `IndexedStack` | Rutas | ✅ |
| 4 | `ApiClient` sobre `http`: Bearer, JSON, timeout de 60 s, "Conectando…" a los 3 s, 401 → login, `ProblemDetails` → `ApiException` y `SocketException` → `NoConnectionException` | Networking | ✅ |
| 5 | Modelos con `fromJson`/`toJson` escritos a mano y enums numéricos mapeados | Networking | ✅ |
| 6 | `FutureBuilder` para cargas de solo lectura (guía desde assets, familia en Perfil) | Networking | ✅ |
| 7 | BLoC con eventos y estados para Auth y Alertas | Patrón de estado | ✅ |
| 8 | Cubit para Resumen, Tips, Perfil y Vincular | Patrón de estado | ✅ |
| 9 | `BlocProvider`, `BlocBuilder` y `RepositoryProvider`; dependencias por constructor | Patrón de estado | ✅ |
| 10 | sqflite + path como caché de alertas y tips (reemplaza las filas); `shared_preferences` para la sesión, los T&C, los toggles y el teléfono | Persistencia | ✅ |
| 11 | `LayoutBuilder`: `NavigationBar` hasta 600 dp y `NavigationRail` por encima; `Switch.adaptive`, `CircularProgressIndicator.adaptive` y `AlertDialog.adaptive` | Diseño adaptable | ✅ |
| 12 | `ListView.builder` en Alertas; `CustomScrollView` + `SliverAppBar` + `SliverList` en Inicio | Colecciones | ✅ |
| 13 | `assets/` declarado en el `pubspec` (JSON e ilustraciones) e `Image.asset(fit: BoxFit.cover)` | Recursos | ✅ |
| 14 | `mobile_scanner` con permiso declarado y caso de permiso denegado; `url_launcher` con `tel:` (madre y 106) | Recursos del dispositivo | ✅ |
| 15 | T&C con aceptación explícita obligatoria (checkbox) antes de usar la app | Términos y condiciones | ✅ |
| 16 | Nunca se muestran ni se piden valores clínicos; nunca se llama a `/api/pregnancy`, `/api/telemetry` ni `/api/triage` | Ética y privacidad | ✅ |
| 17 | `Semantics` en las tarjetas, texto escalable, botones de al menos 48 dp y tema central (paleta y Plus Jakarta Sans) | Calidad | ✅ |
| 18 | Solo los 10 paquetes permitidos | Reglas del curso | ✅ |
| 19 | `BASE_URL` por `--dart-define`; permisos de Android e iOS; HTTP sin cifrar solo en debug | Configuración | ✅ |
| 20 | Fechas con `DateTime.parse` y comparación por valor; `.toLocal()` e `intl` para mostrarlas | Networking | ✅ |
| 21 | P0 Splash: T&C → token → `GET /api/family` (200 a Inicio, 404 a Vincular) | Rutas | ✅ |
| 22 | P1 Login/Registro: "Soy acompañante", contraseña de 10 a 128 caracteres, errores por campo, rechazo de cuentas `Mother` | Widgets / Networking | ✅ |
| 23 | P1b T&C: los 4 puntos, checkbox obligatorio y modo lectura desde Perfil | Términos y condiciones | ✅ |
| 24 | P2 Vincular: QR o clave `HM-XXXX`, 404 y 409 con mensajes | Recursos del dispositivo | ✅ |
| 25 | P3 Inicio: alerta activa con 3 respuestas, SOS roja con llamadas, estado sin números y misión del día | Colecciones / Patrón de estado | ✅ |
| 26 | P4 Alertas: pendientes primero, pull-to-refresh, polling cada 15 s con Inicio o Alertas visibles y caché sin conexión | Colecciones / Persistencia | ✅ |
| 27 | P5 Guía: tips con "Hecho" y contenido semanal con ilustración | Recursos | ✅ |
| 28 | P6 Perfil: datos, "Acompañando a…", teléfono, toggles, T&C y cerrar sesión (borra la sesión y sqflite) | Persistencia / Diseño adaptable | ✅ |
| 29 | Estados cargando, vacío, error con "Reintentar" y sin conexión con widgets comunes | Calidad | ✅ |
| 30 | Mapeo de `healthLight`, `type`, `status` y `response` a español | Networking | ✅ |
| 31 | 409 "no vinculado" en summary, tips o alerts → Vincular | Rutas | ✅ |
| 32 | Respuesta optimista que se revierte si falla; 409 cuenta como éxito y recarga | Patrón de estado | ✅ |
| 33 | "Hecho" al instante, idempotente y guardado en sqflite | Persistencia | ✅ |
| 34 | Tests: widget de la tarjeta (pendiente → respondida y SOS), `AlertsBloc` sin `bloc_test` y `fromJson` de cada modelo con los `null` de D.2 | Calidad | ✅ |
| 35 | `flutter analyze` y `flutter test` en cada bloque, con commits Conventional | Calidad | ✅ |
| 36 | Instrucciones de ejecución y del flujo completo (este README) | — | ✅ |

## Limitaciones conocidas

- **Pruebas en dispositivo:** la app se compiló e instaló en un emulador Android, donde arrancó y mostró los T&C. El resto de las pantallas está cubierto por tests de widgets, pero falta recorrer el flujo completo contra Render y con la app de la madre (pasos de arriba). iOS no se compiló, porque el proyecto se desarrolló en Windows.
- **Notificaciones push:** no hay (Firebase no está permitido). El toggle "Tip del día" solo guarda la preferencia, y el de "Alertas" activa o pausa el polling.
- **Teléfono de la madre:** el backend no lo guarda, así que el acompañante lo ingresa en Perfil y queda solo en su teléfono.
- **Guía semanal:** es contenido general y no reemplaza la indicación médica.
