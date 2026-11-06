import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/time_format.dart';
import '../../data/companion_summary.dart';

/// "Estado de {madre} hoy": color del semáforo, mensaje y semana.
/// Nunca muestra valores clínicos.
class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.summary});

  final CompanionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = summary.healthLight;

    // El color va siempre con un ícono distinto: no dependemos solo del color.
    final (Color color, Color container, IconData icon) = switch (light) {
      HealthLight.green => (
        StatusColors.green,
        StatusColors.greenContainer,
        Icons.check_circle,
      ),
      HealthLight.yellow => (
        StatusColors.amber,
        StatusColors.amberContainer,
        Icons.warning_amber_rounded,
      ),
      HealthLight.red => (
        StatusColors.red,
        StatusColors.redContainer,
        Icons.error,
      ),
      null => (
        theme.colorScheme.outline,
        theme.colorScheme.surfaceContainer,
        Icons.help_outline,
      ),
    };

    final weeks = summary.gestationalWeeks;
    final days = summary.gestationalDays;
    final measuredAt = summary.measuredAt;

    return Semantics(
      container: true,
      child: Card(
        color: container,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Estado de ${summary.motherName} hoy',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 40, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: light == null
                        ? Text(
                            'Aún no hay mediciones de salud. Cuando '
                            '${summary.motherName} registre una, verás aquí '
                            'su semáforo.',
                            style: theme.textTheme.bodyMedium,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Semáforo ${light.label.toLowerCase()}',
                                style: theme.textTheme.titleMedium,
                              ),
                              if (summary.healthSummary != null)
                                Text(
                                  summary.healthSummary!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              if (measuredAt != null)
                                Text(
                                  'Actualizado ${timeAgo(measuredAt)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weeks == null
                          ? '${summary.motherName} aún no registró su embarazo.'
                          : 'Semana $weeks · Día ${days ?? 0}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
