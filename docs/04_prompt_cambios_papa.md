# Prompt: cambios y UI de la app del papá (HelpMom Compañero, Flutter)

## Antes de pegar el prompt

1. Copia la imagen `ui/figma_helpmom_pantallas.png` a la carpeta `docs/` de tu proyecto `helpmom_companion`.
2. Copia también el contrato actualizado `00_contrato_api_backend.md` a `docs/`, reemplazando el anterior.
3. Abre Claude Code en la carpeta del proyecto y pega el bloque de abajo.

> El cambio 1 (desmarcar misión) necesita que el backend ya tenga el endpoint `DELETE /api/companion/tips/{id}/done`. Ese cambio está hecho pero falta subirlo a Render. Si lo pruebas antes y responde 404 o 405, es por eso.

---

```
Trabaja sobre esta app Flutter (Modo Compañero de HelpMom). Lee primero docs/02_prompt_flutter_papa.md, docs/00_contrato_api_backend.md (está actualizado) y mira la imagen docs/figma_helpmom_pantallas.png: es el diseño de Figma que hay que seguir (frames 4, 5 y 8 son del papá).

Reglas: mantén el código simple y al nivel del curso (flutter_bloc con Cubit/Bloc, http, sqflite, shared_preferences). No agregues paquetes nuevos. Un commit Conventional Commit por punto. Al final corre flutter analyze y flutter test y arregla lo que falle.

## Cambios funcionales

1. feat(missions): poder desmarcar una misión marcada por error.
   - En MissionList, el CheckboxListTile ya no se deshabilita cuando tip.done es true: al tocarlo de nuevo se desmarca.
   - TipsCubit: agrega toggle(tipId). Si el tip no está hecho llama markTipDone (POST /api/companion/tips/{id}/done); si ya está hecho llama unmarkTipDone (DELETE /api/companion/tips/{id}/done). Cambio optimista y si falla se revierte con un SnackBar, igual que hoy.
   - Agrega unmarkTipDone en CompanionApi y CompanionRepository, y actualiza el cache de sqflite.
   - Tests del cubit: marcar, desmarcar y revertir si falla.

2. feat(alerts): aviso destacado cuando llega un SOS, con el motivo y acciones.
   - El backend ahora manda en el SOS automático el motivo detectado, por ejemplo: "Alerta automática: el asistente detectó una posible emergencia: sangrado abundante" o "Alerta automática: la medición de salud salió en rojo".
   - En QuickAlert agrega un getter sosReason que devuelva el texto después de "emergencia: " (o "Medición de salud en rojo" si es por la medición, o null si no es SOS automático).
   - En AlertCard, cuando es SOS, muestra arriba en grande "Motivo: {sosReason}" (sin comillas ni cursiva), y abajo los botones que ya existen: "Voy en camino", "Llamar a {mamá}" y "Llamar al 106 (SAMU)".
   - Cuando el AlertsBloc detecte un SOS pendiente NUEVO (que no estaba en la lista anterior), abre automáticamente un diálogo de pantalla completa rojo (showDialog con un Dialog.fullscreen, barrierDismissible: false) con: ícono de alerta, "{mamá} necesita ayuda", el motivo, y los tres botones. El diálogo se cierra solo cuando el papá responde o toca "Ya lo vi". Responder desde ahí llama a POST /api/alerts/{id}/respond como hoy.
   - Para que el aviso llegue sin deslizar, en CompanionShell agrega un Timer.periodic de 15 s que pida AlertsRefreshRequested(AlertsView.home) y SummaryCubit.load() mientras la app está abierta. Cancélalo en dispose. Nada de servicios en segundo plano.
   - Tests: sosReason con los dos tipos de mensaje y que el bloc marque el SOS nuevo una sola vez.

3. feat(home): semáforo más visible.
   - En HomeScreen, pon la tarjeta del estado (StatusCard) arriba de la tarjeta de alertas cuando no hay alerta pendiente. Si hay alerta pendiente, la alerta va primero.

## UI según el Figma (frames 4, 5 y 8)

4. style(ui): igualar el diseño del Figma sin cambiar la lógica.
   - Header de Inicio: avatar circular terracota con la inicial del papá, debajo un chip pequeño "Modo Compañero" (fondo terracota claro, texto terracota) y "Hola, {nombre}" en negrita. A la derecha, en gris, "{mamá} (Sem. X)". Fondo blanco, no el AppBar terracota grande actual.
   - Tarjeta de alerta pendiente (frame 4): fondo crema #FFF8E7 con borde ámbar #F2C94C de 1.5 dp y esquinas de 16 dp. Título "⚠ {mamá} pulsó 'Pasa la Voz'" en ámbar oscuro y a la derecha "Hace N min". El mensaje va en una caja blanca con borde gris claro. Dos botones en fila: "Voy en camino" relleno terracota y "Llamando ahora" con borde terracota.
   - Tarjeta respondida (frame 5): borde verde #2E7D32, título "✓ Solicitud confirmada" en verde, botón verde "Respondido ✓" deshabilitado.
   - Tarjeta "Estado de {mamá} hoy": fondo blanco, título en negrita, ícono del semáforo de 40 dp con su color y un badge píldora a la derecha ("Estable" verde, "Atención" ámbar, "Urgente" rojo). Texto secundario en gris.
   - "Misión de apoyo de hoy": cada tip en una fila con borde gris muy claro y esquinas de 12 dp; el tip hecho se ve tachado y en gris con el check verde.
   - Barra inferior: NavigationBar con íconos de Material (home_rounded, notifications_rounded, menu_book_rounded, person_rounded), el indicador de la pestaña activa en terracota claro y la etiqueta activa en terracota.
   - Vincular (frame 8): título centrado "Conecta con tu pareja", subtítulo gris, campo para la clave "HM-XXXX" con fuente monoespaciada y letras grandes, botón "Escanear código QR" con borde azul y los pasos numerados en una tarjeta gris claro.
   - Todas las tarjetas: blancas sobre el fondo #F0F4F8, esquinas de 16 dp, borde #E3E8EF de 1 dp, sin sombras fuertes. Espaciado de 16 dp.
   - Usa los colores del AppTheme (agrega ahí los nuevos tokens: alertContainer #FFF8E7 y alertBorder #F2C94C). No pongas hexadecimales en las pantallas.

Cuando termines, muéstrame una lista de lo que cambiaste por archivo y qué tests agregaste.
```
