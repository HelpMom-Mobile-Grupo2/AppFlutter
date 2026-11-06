# PROMPT: App HelpMom para el ACOMPAÑANTE / PAPÁ (Flutter · Dart)

Eres un desarrollador Flutter senior. Vas a construir la app **HelpMom – Modo Compañero** en **Flutter (Dart 3, Material 3)** para Android e iOS, conectada al backend real que ya está desplegado. El contrato de la API está en @docs/00_contrato_api_backend.md: léelo completo antes de empezar y respeta exactamente sus rutas, JSON y enums.

La app de la madre es otra app, hecha en Android nativo. **No** construyas pantallas de la madre aquí: ni registro clínico, ni chat, ni Mi Cuerpo.

---

## 0. Reglas del curso (obligatorias)

El curso es "Aplicaciones para dispositivos móviles" (UPC). El código debe ser **sencillo y fácil de explicar en clase**, pero tiene que cubrir **todo** lo que se ve en el curso. Usa **solo** estos paquetes. Si algo no está en la lista, no lo agregues sin preguntarme.

| Tema del curso | Qué usar | Dónde se usa en HelpMom |
|---|---|---|
| Widgets | `StatelessWidget` para lo que solo pinta datos y `StatefulWidget` para formularios, checks y escáner. `Scaffold`, `Column`, `Row`, `Container`, `Card`, `ListTile`, `Icon`, `Image` | Todas las pantallas |
| Rutas | `MaterialApp` con **rutas con nombre** (`routes` + `Navigator.pushNamed`/`pushReplacementNamed`). Las 4 pestañas van en un `Scaffold` con `NavigationBar` e `IndexedStack` | Todo el flujo |
| Networking | Paquete **`http`**, con modelos `fromJson`/`toJson` hechos a mano. `FutureBuilder` para cargas simples de solo lectura | Todo el backend |
| Patrón de estado | **BLoC** con **`flutter_bloc`**: `Bloc` con eventos y estados para Auth y Alertas, y `Cubit` para Resumen, Tips y Perfil. `BlocProvider` y `BlocBuilder` | Pantallas con lógica |
| Persistencia | **`sqflite` + `path`** para la base local, y `shared_preferences` solo para la sesión y los toggles | Caché offline de alertas y tips |
| Diseño adaptable | `LayoutBuilder`: con 600 dp o menos, `NavigationBar`; con más, `NavigationRail`. Constructores `.adaptive()` (`Switch.adaptive`, `CircularProgressIndicator.adaptive`) | Contenedor principal y Perfil |
| Colecciones | `ListView.builder` para listas largas, y en Inicio un `CustomScrollView` con `SliverAppBar` y `SliverList` | Alertas e Inicio |
| Recursos | `assets/` declarado en `pubspec.yaml` (JSON de la guía semanal e ilustraciones), con `Image.asset(fit: BoxFit.cover)` | Guía |
| Recursos del dispositivo | **`mobile_scanner`** (cámara, con el permiso declarado y el caso de permiso denegado) y **`url_launcher`** (`tel:`) | Vincular y alerta SOS |
| Términos y condiciones | Pantalla con aceptación explícita obligatoria antes de usar la app | Registro |
| Ética y privacidad | La app **nunca** muestra ni pide valores clínicos | Toda la app |
| Calidad | Material Design y HIG: `Semantics`, texto escalable, botones de al menos 48 dp | Toda la app |

Paquetes permitidos: `http`, `flutter_bloc`, `equatable`, `sqflite`, `path`, `shared_preferences`, `mobile_scanner`, `url_launcher`, `google_fonts` e `intl`. **No uses:** `dio`, `provider`, `riverpod`, `get`/GetX, `go_router`, `drift`, `freezed`, `json_serializable`, `get_it` ni Firebase. Las dependencias se pasan por constructor o con `RepositoryProvider`.

## 1. Contexto del producto

HelpMom acompaña a la pareja durante el embarazo. El acompañante (Mateo, de 18 a 40 años, Lima) quiere ayudar, pero no sabe cómo y se siente un "espectador". Su app le da:
1. **Estado resumido** de la madre y el bebé: color del semáforo y un mensaje cálido. **Nunca** valores clínicos ni síntomas.
2. **Alertas "Pasa la Voz"** que envía la madre (antojo, cansancio o dolor, "ven un momento" y SOS), con respuesta de un toque.
3. **"Misión de apoyo de hoy":** tips accionables según la semana de gestación.
4. **Explicación semanal sin tecnicismos** de lo que les pasa a la madre y al bebé.

Tono: directo, práctico, "al grano" y empático. Todo el texto visible va en **español** y el código en **inglés**.

## 2. Configuración técnica

- Flutter estable, Dart 3, `useMaterial3: true`.
- `baseUrl` con `--dart-define=BASE_URL=...`. Por defecto es **`https://helpmom-backend.onrender.com/`**. Para el backend local: `http://10.0.2.2:61614/` (emulador Android) o `http://localhost:61614/` (simulador iOS).
- Un `ApiClient` único sobre `http` que:
  - agrega `Authorization: Bearer <token>` y `Content-Type: application/json`,
  - usa un timeout de **60 s** (Render tarda hasta ~50 s en despertar) y muestra "Conectando con el servidor…" si la llamada tarda más de 3 s,
  - ante un **401**, borra la sesión y navega al login con una `GlobalKey<NavigatorState>`,
  - convierte el `ProblemDetails` (`title`, `detail`, `errors`) en una `ApiException`, y una `SocketException` en `NoConnectionException`.
- **Fechas:** `DateTime.parse(...)` y comparar con `isBefore`/`difference`, **nunca el texto** (ver D.11 del contrato). Para mostrarlas, `.toLocal()` e `intl`.
- **Android:** permisos `INTERNET` y `CAMERA`. Texto plano solo en debug (`android:usesCleartextTraffic="true"` en `src/debug/AndroidManifest.xml`), para el backend local. **iOS:** `NSCameraUsageDescription` y una excepción ATS para `localhost` solo en debug.

## 3. Estructura

```
lib/
  main.dart                 // MaterialApp, rutas, tema, providers
  core/      api_client.dart, api_exception.dart, session_store.dart (shared_preferences),
             local_db.dart (sqflite), app_theme.dart, widgets/ (estados de carga, vacío, error y sin conexión)
  features/
    auth/        data (models, auth_api, auth_repository) · bloc (auth_bloc, auth_event, auth_state) · ui (login_screen, terms_screen)
    family/      data · cubit · ui (link_screen, scanner_screen)
    companion/   data (summary, tips) · cubit (summary_cubit, tips_cubit) · ui (home_screen, guide_screen)
    alerts/      data (alert_model, alerts_api, alerts_repository con caché sqflite) · bloc (alerts_bloc) · ui (alerts_screen, alert_card)
    profile/     cubit · ui (profile_screen)
  assets/weekly_guide.json
```

Cada repositorio es una **clase concreta** que usa el `ApiClient` (y `LocalDb` cuando aplica). No hagas implementaciones simuladas (Fake): el backend ya está completo. Para los tests, crea un repositorio de prueba dentro de `test/`.

## 4. Estilo visual (Modo Compañero)

- Misma marca que la app de la madre, con **acento terracota** para distinguir el rol:
  - Secundario/acento `#E07A5F` en el header ("Modo Compañero"), la pestaña activa y los botones de respuesta.
  - Primario `#4A6FA5`, surface `#FBFBFC`, surface-container `#F0F4F8` y texto `#1A1C1E`.
- **Semáforo:** verde `#2E7D32` (contenedor `#E8F5E9`), ámbar `#EF6C00` y rojo `#C62828`.
- **Tipografía:** Plus Jakarta Sans (`google_fonts`) con la escala de Material 3.
- **Formas:** tarjetas con esquinas de 16 a 24 dp y botones de respuesta grandes, de al menos 48 dp. Usa `Semantics` en las tarjetas.
- Todo en un `ThemeData` centralizado en `app_theme.dart`. No uses colores sueltos en las pantallas.

## 5. Pantallas (rol Acompañante)

Navegación principal con 4 destinos: **Inicio · Alertas · Guía · Perfil**.

| # | Pantalla | Contenido | Backend |
|---|---|---|---|
| P0 | **Splash** | Si no aceptó los T&C, va a P1b. Sin token, va a P1. Con token, llama a `GET /api/family`: 200 va a P3 y 404 va a P2 | `shared_preferences` + `GET /api/family` |
| P1 | **Login / Registro** | Texto "Soy acompañante". Pestañas Ingresar y Crear cuenta: nombre, correo y contraseña (de 10 a 128 caracteres). Errores de `errors` bajo cada campo. Si el login devuelve `role == "Mother"`, muestra "Esta cuenta es de gestante: usa la app HelpMom para mamá" y no guarda la sesión | `POST /api/auth/login`, `POST /api/auth/register` con `"role": "Partner"` |
| P1b | **Términos y condiciones** | Texto (basado en las plantillas del curso) que cubre: es una **simulación educativa**, el acompañante **solo** ve el color del semáforo, la semana y las alertas (nunca datos clínicos), la madre puede desvincularlo cuando quiera y el uso responsable de las alertas SOS. Checkbox "Leí y acepto" obligatorio, botón deshabilitado hasta marcarlo y guardado en `shared_preferences`. Accesible también desde Perfil | (local) |
| P2 | **Vincular con tu pareja** | Explicación, botón "Escanear código QR" (pantalla con `MobileScanner`; si se niega el permiso, explica cómo activarlo y ofrece la clave manual) y campo "Ingresar clave" (formato `HM-XXXX`, validado en la app). Al vincular: "¡Listo! Ahora acompañas a {motherName}". Errores: 404 "Ese código no existe", 409 con el `detail` del backend | `POST /api/family/join` |
| P3 | **Inicio** | `CustomScrollView` con un `SliverAppBar` terracota: "Modo Compañero · Hola, {nombre}" y "{motherName} (Sem. X)". **Tarjeta de alerta activa** (la pendiente más reciente): "🔔 {motherName} pulsó 'Pasa la Voz'", hace N min, el mensaje entre comillas y los botones **"Voy en camino"**, **"Te llamo ahora"** y **"Ya me encargué"**. Al responder, la tarjeta pasa a verde: "✓ Solicitud confirmada · Respondido". Si la alerta es **SOS** (`type 4`), se muestra una tarjeta roja a todo lo ancho con "Llamar a {motherName}" y "Llamar al 106" (`url_launcher`), y sus botones de respuesta. **Tarjeta "Estado de {motherName} hoy"**: color del semáforo, `healthSummary` y "Semana X · Día Y", **sin números**; si `healthLight` o las semanas llegan `null`, un estado vacío. **"Misión de apoyo de hoy"**: los 3 tips como checklist | `GET /api/companion/summary`, `GET /api/alerts?status=pending`, `POST /api/alerts/{id}/respond`, `GET /api/companion/tips/today`, `POST /api/companion/tips/{id}/done` |
| P4 | **Alertas** | Bandeja con `ListView.builder`: pendientes arriba y luego el historial. Cada fila muestra el ícono del tipo, el mensaje, la hora, el estado y la respuesta dada. Pull-to-refresh (`RefreshIndicator`) y **polling cada 15 s solo mientras la pestaña está visible**, con un `Timer.periodic` que el `AlertsBloc` cancela en `close()`. Sin internet, muestra lo último guardado en **sqflite** con el aviso "Sin conexión · mostrando lo último guardado" | `GET /api/alerts` (por defecto `all`) |
| P5 | **Guía** | Dos secciones. **"¿Cómo ayudar hoy?"**: los tips del día, cada uno con el check "Hecho". **"Qué está pasando esta semana"**: contenido local de `assets/weekly_guide.json` por semana (bebé, cambios en la madre, cómo ayudar y preparativos como el bolso o los trámites), con una ilustración de `assets/` | `GET /api/companion/tips/today`, `POST /api/companion/tips/{id}/done` + local |
| P6 | **Perfil** | Nombre, correo, "Acompañando a {motherName}" (de `GET /api/family`), preferencias de notificaciones (toggles `Switch.adaptive` guardados en `shared_preferences`: tip del día y alertas), "Términos y condiciones" y "Cerrar sesión" (borra la sesión y las tablas de sqflite) | `GET /api/family` |

Estados obligatorios en cada pantalla, con widgets comunes: **cargando**, **vacío** ("Aún no hay alertas, te avisaremos cuando {motherName} te necesite"), **error** (con "Reintentar") y **sin conexión**.

## 6. Reglas de negocio en la app

- **Mapeo de enums** (llegan como números):
  - `healthLight`: 1/2/3 → Verde/Amarillo/Rojo
  - alerta `type`: 1 Antojo, 2 Cansancio/Dolor, 3 Ven un momento, 4 SOS
  - `status`: 1 Pendiente, 2 Respondida
  - `response`: 1 Voy en camino, 2 Te llamo ahora, 3 Ya me encargué
- **Privacidad:** la app solo consume `/api/auth/*`, `/api/family` (GET y `join`), `/api/companion/*` y `/api/alerts`. **Nunca** llama a `/api/pregnancy`, `/api/telemetry` ni `/api/triage`.
- **Partner sin vincular** (D.7 del contrato): un 409 con "Aún no estás vinculado a una gestante." en summary, tips o alerts lleva a P2.
- **Respuesta a una alerta:** se aplica de forma optimista en la UI y se revierte si falla. Un 409 ("ya estaba respondida") se trata como éxito y se recarga la lista.
- **Tips:** marcar "Hecho" es idempotente. Se marca en la UI al instante y se guarda en sqflite para verlo sin conexión.
- **sqflite es caché, no la fuente de la verdad:** al recibir datos de la API, reemplaza las filas de la tabla.

## 7. Entregables y orden de trabajo

1. Antes de programar, haz una **lista numerada de requisitos** a partir de las secciones 0 y 5. Muéstrame el **plan**, el `pubspec.yaml` completo y la estructura de `lib/`, y **espera mi OK**.
2. Avanza por bloques. Al final de cada bloque corre `flutter analyze` y `flutter test`, y haz un commit con Conventional Commits en inglés (`feat(alerts): ...`):
   1. tema, rutas y contenedor adaptable,
   2. `ApiClient`, sesión y sqflite,
   3. P1, P1b y P2,
   4. P3,
   5. P4,
   6. P5,
   7. P6.
3. Escribe el **código completo** de cada archivo, con su ruta, sin "…".
4. **Tests:**
   - un widget test de la tarjeta de alerta (pendiente → respondida, y la variante SOS),
   - un test del `AlertsBloc` con `flutter_test` (sin el paquete `bloc_test`), usando un repositorio de prueba: cargar, responder con éxito y revertir si falla,
   - tests de `fromJson` de cada modelo con los JSON del contrato, incluidos los `null` de la sección D.2.
5. Al final, explica cómo correrla contra Render (`flutter run`) y contra el backend local (`flutter run --dart-define=BASE_URL=http://10.0.2.2:61614/`), y cómo probar el flujo completo con la app de la madre: registrarse como acompañante, vincular con el código, recibir "Pasa la Voz" y responder, ver la SOS automática después de una medición roja y consultar el resumen.
6. Al terminar, marca la lista de requisitos como checklist final, indicando qué tema del curso cubre cada uno.
