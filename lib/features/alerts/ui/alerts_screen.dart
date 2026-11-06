import 'package:flutter/material.dart';

/// P4 Alertas. Pantalla temporal: se completa en el bloque 5.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: const Center(child: Text('Bandeja de alertas')),
    );
  }
}
