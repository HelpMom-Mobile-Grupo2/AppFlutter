import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../data/daily_tip.dart';

/// Checklist de los tips del día. Tocar un tip hecho lo desmarca, por si
/// se marcó por error.
class MissionList extends StatelessWidget {
  const MissionList({
    super.key,
    required this.tips,
    required this.onToggle,
    this.title = 'Misión de apoyo de hoy',
    this.showBody = false,
    this.isOffline = false,
  });

  final List<DailyTip> tips;
  final ValueChanged<String> onToggle;
  final String title;

  /// En Guía se muestra el texto completo de cada tip.
  final bool showBody;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      container: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isOffline)
                Text(
                  'Sin conexión · mostrando lo último guardado',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              const SizedBox(height: 12),
              if (tips.isEmpty)
                Text(
                  'Hoy no hay misiones. ¡Vuelve mañana!',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              for (final tip in tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MissionRow(
                    tip: tip,
                    showBody: showBody,
                    onToggle: () => onToggle(tip.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una fila con borde gris muy claro. Hecha: tachada, en gris y con el
/// check verde.
class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.tip,
    required this.showBody,
    required this.onToggle,
  });

  final DailyTip tip;
  final bool showBody;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // tileColor y shape (con borde) los pinta el propio ListTile, así el
    // efecto al tocar se sigue viendo.
    return CheckboxListTile(
      value: tip.done,
      onChanged: (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      tileColor: tip.done ? scheme.surfaceContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      activeColor: StatusColors.green,
      checkColor: scheme.onPrimary,
      title: Text(
        tip.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: tip.done ? scheme.onSurfaceVariant : scheme.onSurface,
          decoration: tip.done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: showBody
          ? Text(
              tip.body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          : null,
      // En Guía la etiqueta "Hecho" acompaña siempre al check.
      secondary: showBody || tip.done
          ? Text(
              'Hecho',
              style: theme.textTheme.labelMedium?.copyWith(
                color: tip.done ? StatusColors.green : scheme.onSurfaceVariant,
              ),
            )
          : null,
    );
  }
}
