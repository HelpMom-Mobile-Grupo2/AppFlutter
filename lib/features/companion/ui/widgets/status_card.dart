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
    final muted = theme.colorScheme.onSurfaceVariant;
    final light = summary.healthLight;

    // El color va siempre con un ícono y un texto distintos: no dependemos
    // solo del color.
    final (Color color, IconData icon) = switch (light) {
      HealthLight.green => (StatusColors.green, Icons.check_circle),
      HealthLight.yellow => (StatusColors.amber, Icons.warning_amber_rounded),
      HealthLight.red => (StatusColors.red, Icons.error),
      null => (muted, Icons.help_outline),
    };

    final weeks = summary.gestationalWeeks;
    final days = summary.gestationalDays;
    final measuredAt = summary.measuredAt;

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
                  'Estado de ${summary.motherName} hoy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Semáforo ${light.label.toLowerCase()}',
                                style: theme.textTheme.titleSmall,
                              ),
                              if (summary.healthSummary != null)
                                Text(
                                  summary.healthSummary!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: muted,
                                  ),
                                ),
                              if (measuredAt != null)
                                Text(
                                  'Actualizado ${timeAgo(measuredAt)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                  ),
                                ),
                            ],
                          ),
                  ),
                  if (light != null) ...[
                    const SizedBox(width: 8),
                    _LightBadge(light: light),
                  ],
                ],
              ),
              const Divider(height: 24, color: AppColors.cardBorder),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 20, color: muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weeks == null
                          ? '${summary.motherName} aún no registró su embarazo.'
                          : 'Semana $weeks · Día ${days ?? 0}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
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

/// Píldora "Estable", "Atención" o "Urgente" a la derecha del semáforo.
class _LightBadge extends StatelessWidget {
  const _LightBadge({required this.light});

  final HealthLight light;

  @override
  Widget build(BuildContext context) {
    final (String label, Color text, Color background) = switch (light) {
      HealthLight.green => (
        'Estable',
        StatusColors.green,
        StatusColors.greenContainer,
      ),
      HealthLight.yellow => (
        'Atención',
        StatusColors.amberText,
        StatusColors.amberContainer,
      ),
      HealthLight.red => (
        'Urgente',
        StatusColors.red,
        StatusColors.redContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: text, fontWeight: FontWeight.w700),
      ),
    );
  }
}
