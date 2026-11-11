import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_routes.dart';
import '../../../core/phone_launcher.dart';
import '../../alerts/bloc/alerts_bloc.dart';
import '../../alerts/data/alert_model.dart';
import '../../alerts/ui/alert_actions.dart';
import '../../alerts/ui/alerts_screen.dart';
import '../../alerts/ui/sos_dialog.dart';
import '../../profile/ui/profile_screen.dart';
import '../cubit/summary_cubit.dart';
import '../cubit/tips_cubit.dart';
import 'guide_screen.dart';
import 'home_screen.dart';

class _Destination {
  const _Destination(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _destinations = [
  _Destination('Inicio', Icons.home_rounded),
  _Destination('Alertas', Icons.notifications_rounded),
  _Destination('Guía', Icons.menu_book_rounded),
  _Destination('Perfil', Icons.person_rounded),
];

const _pages = [HomeScreen(), AlertsScreen(), GuideScreen(), ProfileScreen()];

/// Contenedor de las 4 pestañas. Con 600 dp o menos usa NavigationBar abajo;
/// con más ancho, NavigationRail a la izquierda.
///
/// También avisa al AlertsBloc qué pestaña se ve, para que el polling corra
/// solo con Inicio o Alertas en pantalla y la app en primer plano.
///
/// Además, cada [refreshInterval] pide las alertas pendientes y el resumen
/// (en cualquier pestaña) para que una SOS nueva abra su aviso sin tener que
/// deslizar. Solo mientras la app está abierta: no hay servicios en segundo
/// plano.
class CompanionShell extends StatefulWidget {
  const CompanionShell({
    super.key,
    this.refreshInterval = const Duration(seconds: 15),
  });

  static const breakpoint = 600.0;

  final Duration refreshInterval;

  @override
  State<CompanionShell> createState() => _CompanionShellState();
}

class _CompanionShellState extends State<CompanionShell> {
  // La GlobalKey conserva el estado de las pestañas al girar el teléfono,
  // cuando el IndexedStack cambia de lugar en el árbol.
  final _pagesKey = GlobalKey();
  late final AppLifecycleListener _lifecycleListener;
  Timer? _refreshTimer;
  int _index = 0;
  bool _appVisible = true;
  bool _leaving = false;
  bool _sosDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onShow: () => _setAppVisible(true),
      onHide: () => _setAppVisible(false),
    );
    _notifyAlertsView();
    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!_appVisible) return;
    context.read<AlertsBloc>().add(
      const AlertsRefreshRequested(AlertsView.home),
    );
    context.read<SummaryCubit>().load();
  }

  void _setAppVisible(bool visible) {
    _appVisible = visible;
    _notifyAlertsView();
  }

  void _onDestinationSelected(int index) {
    setState(() => _index = index);
    _notifyAlertsView();
  }

  void _notifyAlertsView() {
    final view = !_appVisible
        ? null
        : switch (_index) {
            0 => AlertsView.home,
            1 => AlertsView.inbox,
            _ => null,
          };
    context.read<AlertsBloc>().add(AlertsVisibilityChanged(view));
  }

  /// 409 "Aún no estás vinculado" en summary, tips o alerts (D.7).
  void _goToLink() {
    if (_leaving) return;
    _leaving = true;
    Navigator.pushReplacementNamed(context, AppRoutes.link);
  }

  /// Aviso rojo de pantalla completa. Si ya hay uno abierto, no se apila
  /// otro: la SOS más nueva igual queda primera en Inicio.
  Future<void> _showSosDialog(QuickAlert alert) async {
    if (_sosDialogOpen) return;
    _sosDialogOpen = true;

    // El diálogo está en otra ruta y no ve los providers de esta pantalla,
    // por eso se le pasa el cubit con bloc:. Así el nombre aparece aunque el
    // resumen termine de cargar después.
    final summaryCubit = context.read<SummaryCubit>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocBuilder<SummaryCubit, SummaryState>(
        bloc: summaryCubit,
        builder: (_, summary) {
          final motherName = summary is SummaryLoaded
              ? summary.summary.motherName
              : 'Tu pareja';
          return SosDialog(
            alert: alert,
            motherName: motherName,
            onOnMyWay: () =>
                respondToAlert(context, alert.id, AlertResponse.onMyWay),
            onCallMother: () => callMother(context, motherName),
            onCallEmergency: () => callEmergency(context),
          );
        },
      ),
    );
    _sosDialogOpen = false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AlertsBloc, AlertsState>(
          listenWhen: (previous, current) =>
              !previous.notLinked && current.notLinked,
          listener: (_, _) => _goToLink(),
        ),
        BlocListener<SummaryCubit, SummaryState>(
          listenWhen: (_, current) => current is SummaryNotLinked,
          listener: (_, _) => _goToLink(),
        ),
        BlocListener<TipsCubit, TipsState>(
          listenWhen: (_, current) => current is TipsNotLinked,
          listener: (_, _) => _goToLink(),
        ),
        BlocListener<AlertsBloc, AlertsState>(
          listenWhen: (_, current) => current.newSos != null,
          listener: (_, state) => _showSosDialog(state.newSos!),
        ),
        BlocListener<AlertsBloc, AlertsState>(
          listenWhen: (_, current) => current.actionError != null,
          listener: (_, state) => _showMessage(
            'No se pudo enviar tu respuesta. ${state.actionError}',
          ),
        ),
        BlocListener<TipsCubit, TipsState>(
          listenWhen: (_, current) =>
              current is TipsLoaded && current.actionError != null,
          listener: (_, state) => _showMessage(
            'No se pudo actualizar el tip. ${(state as TipsLoaded).actionError}',
          ),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pages = IndexedStack(
            key: _pagesKey,
            index: _index,
            children: [
              // TickerMode pausa las animaciones (por ejemplo, un indicador
              // de carga) de las pestañas que no se ven.
              for (final (i, page) in _pages.indexed)
                TickerMode(enabled: i == _index, child: page),
            ],
          );

          if (constraints.maxWidth <= CompanionShell.breakpoint) {
            return Scaffold(
              body: pages,
              bottomNavigationBar: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _onDestinationSelected,
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(icon: Icon(d.icon), label: d.label),
                ],
              ),
            );
          }

          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  right: false,
                  child: NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _onDestinationSelected,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages),
              ],
            ),
          );
        },
      ),
    );
  }
}
