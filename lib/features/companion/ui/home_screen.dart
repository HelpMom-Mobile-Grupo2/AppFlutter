import 'package:flutter/material.dart';

/// P3 Inicio. Pantalla temporal: se completa en el bloque 4.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Compañero')),
      body: const Center(child: Text('Inicio')),
    );
  }
}
