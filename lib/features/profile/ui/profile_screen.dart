import 'package:flutter/material.dart';

/// P6 Perfil. Pantalla temporal: se completa en el bloque 7.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: const Center(child: Text('Mi perfil')),
    );
  }
}
