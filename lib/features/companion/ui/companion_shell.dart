import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_routes.dart';
import '../../alerts/bloc/alerts_bloc.dart';
import '../../alerts/ui/alerts_screen.dart';
import '../../profile/ui/profile_screen.dart';
import '../cubit/summary_cubit.dart';
import '../cubit/tips_cubit.dart';
import 'guide_screen.dart';
import 'home_screen.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination('Inicio', Icons.home_outlined, Icons.home),
  _Destination('Alertas', Icons.notifications_outlined, Icons.notifications),
  _Destination('Guía', Icons.menu_book_outlined, Icons.menu_book),
  _Destination('Perfil', Icons.person_outline, Icons.person),
];

const _pages = [HomeScreen(), AlertsScreen(), GuideScreen(), ProfileScreen()];

/// Contenedor de las 4 pestañas. Con 600 dp o menos usa NavigationBar abajo;
/// con más ancho, NavigationRail a la izquierda.
///
/// También avisa al AlertsBloc qué pestaña se ve, para que el polling corra
/// solo con Inicio o Alertas en pantalla y la app en primer plano.
class CompanionShell extends StatefulWidget {
  const CompanionShell({super.key});

  static const breakpoint = 600.0;

  @override
  State<CompanionShell> createState() => _CompanionShellState();
}

class _CompanionShellState extends State<CompanionShell> {
  // La GlobalKey conserva el estado de las pestañas al girar el teléfono,
  // cuando el IndexedStack cambia de lugar en el árbol.
  final _pagesKey = GlobalKey();
  late final AppLifecycleListener _lifecycleListener;
  int _index = 0;
  bool _appVisible = true;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onShow: () => _setAppVisible(true),
      onHide: () => _setAppVisible(false),
    );
    _notifyAlertsView();
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
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
          listenWhen: (_, current) => current.actionError != null,
          listener: (_, state) => _showMessage(
            'No se pudo enviar tu respuesta. ${state.actionError}',
          ),
        ),
        BlocListener<TipsCubit, TipsState>(
          listenWhen: (_, current) =>
              current is TipsLoaded && current.actionError != null,
          listener: (_, state) => _showMessage(
            'No se pudo marcar el tip. ${(state as TipsLoaded).actionError}',
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
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
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
                          selectedIcon: Icon(d.selectedIcon),
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
