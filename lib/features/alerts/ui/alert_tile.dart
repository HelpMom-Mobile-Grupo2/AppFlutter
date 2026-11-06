import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/time_format.dart';
import '../data/alert_model.dart';
import 'alert_card.dart';

/// Fila de la bandeja: ícono del tipo, mensaje, hora, estado y respuesta.
class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alert, this.onTap});

  final QuickAlert alert;

  /// Solo las pendientes se pueden abrir para responder.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pending = alert.isPending;

    final status = alert.response == null
        ? alert.status.label
        : '${alert.status.label} · ${alert.response!.label}';

    return Card(
      child: ListTile(
        minVerticalPadding: 12,
        leading: CircleAvatar(
          backgroundColor: alert.isSos
              ? StatusColors.redContainer
              : scheme.secondaryContainer,
          child: Icon(
            alertTypeIcon(alert.type),
            color: alert.isSos ? StatusColors.red : scheme.onSecondaryContainer,
          ),
        ),
        title: Text(alert.message.isEmpty ? alert.type.label : alert.message),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${alert.type.label} · ${timeAgo(alert.createdAt)}'),
            const SizedBox(height: 6),
            _StatusChip(text: status, pending: pending),
          ],
        ),
        trailing: pending
            ? Text(
                'Responder',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                ),
              )
            : null,
        onTap: pending ? onTap : null,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.pending});

  final String text;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pending
            ? theme.colorScheme.secondaryContainer
            : StatusColors.greenContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pending ? Icons.schedule : Icons.check_circle,
            size: 16,
            color: pending
                ? theme.colorScheme.onSecondaryContainer
                : StatusColors.green,
          ),
          const SizedBox(width: 4),
          Flexible(child: Text(text, style: theme.textTheme.labelMedium)),
        ],
      ),
    );
  }
}
