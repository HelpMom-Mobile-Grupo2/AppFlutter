import 'package:flutter/material.dart';

import '../../alerts/ui/alerts_screen.dart';
import '../../profile/ui/profile_screen.dart';
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

/// Contenedor de las 4 pestañas. Con 600 dp o menos usa NavigationBar abajo;
/// con más ancho, NavigationRail a la izquierda.
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
  int _index = 0;

  void _onDestinationSelected(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = IndexedStack(
      key: _pagesKey,
      index: _index,
      children: const [
        HomeScreen(),
        AlertsScreen(),
        GuideScreen(),
        ProfileScreen(),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
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
    );
  }
}
