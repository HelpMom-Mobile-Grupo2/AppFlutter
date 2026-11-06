import 'package:flutter/material.dart';

/// P5 Guía. Pantalla temporal: se completa en el bloque 6.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guía')),
      body: const Center(child: Text('Guía semanal')),
    );
  }
}
