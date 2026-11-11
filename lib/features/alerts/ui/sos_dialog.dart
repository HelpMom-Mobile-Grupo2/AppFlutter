import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../data/alert_model.dart';

/// Aviso rojo de pantalla completa de una SOS nueva. Se abre con showDialog
/// y barrierDismissible: false. Tampoco se cierra con "atrás": solo con
/// "Voy en camino" o "Ya lo vi".
class SosDialog extends StatelessWidget {
  const SosDialog({
    super.key,
    required this.alert,
    required this.motherName,
    required this.onOnMyWay,
    required this.onCallMother,
    required this.onCallEmergency,
  });

  final QuickAlert alert;
  final String motherName;
  final VoidCallback onOnMyWay;
  final VoidCallback onCallMother;
  final VoidCallback onCallEmergency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onRed = theme.colorScheme.onError;
    final reason = alert.sosReason ?? alert.message;

    // Botones claros con texto rojo sobre el fondo rojo.
    final lightButton = FilledButton.styleFrom(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: StatusColors.red,
    );

    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        backgroundColor: StatusColors.red,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(Icons.warning_amber_rounded, size: 96, color: onRed),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    '$motherName necesita ayuda',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: onRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    alert.sosReason == null ? reason : 'Motivo: $reason',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(color: onRed),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  style: lightButton,
                  onPressed: () {
                    Navigator.pop(context);
                    onOnMyWay();
                  },
                  child: Text(AlertResponse.onMyWay.label),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: lightButton,
                  onPressed: onCallMother,
                  icon: const Icon(Icons.phone),
                  label: Text('Llamar a $motherName'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onRed,
                    side: BorderSide(color: onRed),
                  ),
                  onPressed: onCallEmergency,
                  icon: const Icon(Icons.local_hospital_outlined),
                  label: const Text('Llamar al 106 (SAMU)'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: onRed),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ya lo vi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
