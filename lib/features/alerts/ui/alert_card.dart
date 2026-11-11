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

/// Tarjeta de la alerta activa en Inicio (frames 4 y 5 del Figma).
/// - Pendiente: crema con borde ámbar, "Voy en camino" y "Llamando ahora".
/// - SOS pendiente: roja, con el motivo en grande, "Voy en camino",
///   "Llamar a {madre}" y "Llamar al 106 (SAMU)".
/// - Respondida: borde verde, "✓ Solicitud confirmada" y "Respondido ✓".
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

  /// Hora de referencia para "Hace N min" (los tests la fijan).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final responded = !alert.isPending;
    final redCard = alert.isSos && !responded;
    final sosReason = alert.sosReason;

    final Color background;
    final Color border;
    final Color titleColor;
    final Color textColor;
    final String title;
    if (redCard) {
      background = StatusColors.red;
      border = StatusColors.red;
      titleColor = scheme.onError;
      textColor = scheme.onError;
      title = '🆘 SOS de $motherName';
    } else if (responded) {
      background = scheme.surface;
      border = StatusColors.green;
      titleColor = StatusColors.green;
      textColor = scheme.onSurfaceVariant;
      title = '✓ Solicitud confirmada';
    } else {
      background = AppColors.alertContainer;
      border = AppColors.alertBorder;
      titleColor = AppColors.alertTitle;
      textColor = AppColors.alertTitle;
      title = "⚠ $motherName pulsó 'Pasa la Voz'";
    }

    final time = timeAgo(
      responded ? alert.respondedAt ?? alert.createdAt : alert.createdAt,
      now: now,
    );

    return Semantics(
      container: true,
      child: Card(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _capitalize(time),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (sosReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Motivo: $sosReason',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: redCard ? scheme.onError : scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              // En la SOS automática el motivo ya resume el mensaje.
              if (alert.message.isNotEmpty && sosReason == null) ...[
                const SizedBox(height: 12),
                _MessageBox(message: alert.message),
              ],
              if (responded && alert.response != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Respondiste: ${alert.response!.label}',
                  style: theme.textTheme.bodySmall?.copyWith(color: textColor),
                ),
              ],
              const SizedBox(height: 16),
              if (responded)
                FilledButton(
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: StatusColors.green,
                    disabledForegroundColor: scheme.onPrimary,
                  ),
                  onPressed: null,
                  child: const Text('Respondido ✓'),
                )
              else if (redCard)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.surface,
                    foregroundColor: StatusColors.red,
                  ),
                  onPressed: () => onRespond(AlertResponse.onMyWay),
                  child: Text(AlertResponse.onMyWay.label),
                )
              else
                _ResponseButtons(onRespond: onRespond),
              if (alert.isSos) ...[
                const SizedBox(height: 8),
                _CallButtons(
                  motherName: motherName,
                  onRedCard: redCard,
                  onCallMother: onCallMother,
                  onCallEmergency: onCallEmergency,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}

/// El mensaje de la madre en una caja blanca con borde gris claro.
class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text('"$message"', style: theme.textTheme.bodyMedium),
    );
  }
}

/// "Voy en camino" (relleno terracota) y "Llamando ahora" (borde
/// terracota) en fila. "Ya me encargué" queda debajo como botón de texto
/// para no perder esa respuesta.
class _ResponseButtons extends StatelessWidget {
  const _ResponseButtons({required this.onRespond});

  final ValueChanged<AlertResponse> onRespond;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.secondary,
                  foregroundColor: scheme.onSecondary,
                ),
                onPressed: () => onRespond(AlertResponse.onMyWay),
                child: Text(AlertResponse.onMyWay.label),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: scheme.surface,
                  foregroundColor: AppColors.accentText,
                  side: BorderSide(color: scheme.secondary),
                ),
                onPressed: () => onRespond(AlertResponse.callingNow),
                child: const Text('Llamando ahora'),
              ),
            ),
          ],
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.accentText),
          onPressed: () => onRespond(AlertResponse.done),
          child: Text(AlertResponse.done.label),
        ),
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
          label: const Text('Llamar al 106 (SAMU)'),
        ),
      ],
    );
  }
}
