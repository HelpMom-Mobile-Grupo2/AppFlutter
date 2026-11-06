import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/time_format.dart';
import '../data/alert_model.dart';

IconData alertTypeIcon(AlertType type) => switch (type) {
  AlertType.craving => Icons.icecream_outlined,
  AlertType.tiredOrPain => Icons.healing_outlined,
  AlertType.comeHere => Icons.directions_walk,
  AlertType.sos => Icons.sos,
};

/// Tarjeta de la alerta activa en Inicio.
/// - Pendiente: terracota claro con los 3 botones de respuesta.
/// - SOS pendiente: roja, con "Llamar a {madre}" y "Llamar al 106".
/// - Respondida: verde, "✓ Solicitud confirmada · Respondido".
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    required this.motherName,
    required this.onRespond,
    required this.onCallMother,
    required this.onCallEmergency,
    this.now,
  });

  final QuickAlert alert;
  final String motherName;
  final ValueChanged<AlertResponse> onRespond;
  final VoidCallback onCallMother;
  final VoidCallback onCallEmergency;

  /// Hora de referencia para "hace N min" (los tests la fijan).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final responded = !alert.isPending;
    final redCard = alert.isSos && !responded;

    final Color background;
    final Color foreground;
    if (responded) {
      background = StatusColors.greenContainer;
      foreground = scheme.onSurface;
    } else if (redCard) {
      background = StatusColors.red;
      foreground = scheme.onError;
    } else {
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
    }

    final title = alert.isSos
        ? '🆘 SOS de $motherName'
        : "🔔 $motherName pulsó 'Pasa la Voz'";

    return Semantics(
      container: true,
      child: Card(
        color: background,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(alertTypeIcon(alert.type), size: 18, color: foreground),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${alert.type.label} · ${timeAgo(alert.createdAt, now: now)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
              if (alert.message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '"${alert.message}"',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: foreground,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (responded) ...[
                const SizedBox(height: 12),
                _RespondedLine(alert: alert),
              ],
              if (alert.isSos) ...[
                const SizedBox(height: 16),
                _CallButtons(
                  motherName: motherName,
                  onRedCard: redCard,
                  onCallMother: onCallMother,
                  onCallEmergency: onCallEmergency,
                ),
              ],
              if (!responded) ...[
                const SizedBox(height: 16),
                _ResponseButtons(onRedCard: redCard, onRespond: onRespond),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RespondedLine extends StatelessWidget {
  const _RespondedLine({required this.alert});

  final QuickAlert alert;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: StatusColors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✓ Solicitud confirmada · Respondido',
                style: textTheme.titleSmall,
              ),
              if (alert.response != null)
                Text(
                  'Respondiste: ${alert.response!.label}',
                  style: textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResponseButtons extends StatelessWidget {
  const _ResponseButtons({required this.onRedCard, required this.onRespond});

  final bool onRedCard;
  final ValueChanged<AlertResponse> onRespond;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Sobre rojo, botones claros con texto rojo; si no, terracota.
    final style = onRedCard
        ? FilledButton.styleFrom(
            backgroundColor: scheme.surface,
            foregroundColor: StatusColors.red,
          )
        : FilledButton.styleFrom(
            backgroundColor: scheme.secondary,
            foregroundColor: scheme.onSecondary,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final response in AlertResponse.values) ...[
          FilledButton(
            style: style,
            onPressed: () => onRespond(response),
            child: Text(response.label),
          ),
          if (response != AlertResponse.values.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _CallButtons extends StatelessWidget {
  const _CallButtons({
    required this.motherName,
    required this.onRedCard,
    required this.onCallMother,
    required this.onCallEmergency,
  });

  final String motherName;
  final bool onRedCard;
  final VoidCallback onCallMother;
  final VoidCallback onCallEmergency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: onRedCard
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.surface,
                  foregroundColor: StatusColors.red,
                )
              : null,
          onPressed: onCallMother,
          icon: const Icon(Icons.phone),
          label: Text('Llamar a $motherName'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: onRedCard
              ? OutlinedButton.styleFrom(
                  foregroundColor: scheme.onError,
                  side: BorderSide(color: scheme.onError),
                )
              : null,
          onPressed: onCallEmergency,
          icon: const Icon(Icons.local_hospital_outlined),
          label: const Text('Llamar al 106'),
        ),
      ],
    );
  }
}
