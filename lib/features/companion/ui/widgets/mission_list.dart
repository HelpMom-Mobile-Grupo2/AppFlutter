import 'package:flutter/material.dart';

import '../../data/daily_tip.dart';

/// Checklist de los tips del día. Un tip hecho ya no se puede desmarcar
/// (el backend no tiene esa opción).
class MissionList extends StatelessWidget {
  const MissionList({
    super.key,
    required this.tips,
    required this.onDone,
    this.title = 'Misión de apoyo de hoy',
    this.showBody = false,
    this.isOffline = false,
  });

  final List<DailyTip> tips;
  final ValueChanged<String> onDone;
  final String title;

  /// En Guía se muestra el texto completo de cada tip.
  final bool showBody;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
              if (isOffline)
                Text(
                  'Sin conexión · mostrando lo último guardado',
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              if (tips.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Hoy no hay misiones. ¡Vuelve mañana!',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              for (final tip in tips)
                CheckboxListTile(
                  value: tip.done,
                  onChanged: tip.done ? null : (_) => onDone(tip.id),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tip.title,
                    style: tip.done
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          )
                        : null,
                  ),
                  subtitle: showBody ? Text(tip.body) : null,
                  secondary: tip.done
                      ? Text('Hecho', style: theme.textTheme.labelMedium)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
