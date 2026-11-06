import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'session_store.dart';

/// SAMU (emergencias médicas en Perú).
const emergencyNumber = '106';

/// Abre el marcador con [number] (tel:). Sin número, lo abre vacío.
Future<bool> openDialer(String? number) async {
  try {
    return await launchUrl(Uri(scheme: 'tel', path: number ?? ''));
  } on Exception {
    return false;
  }
}

/// Llama a la madre con el teléfono guardado en Perfil. Si no hay uno,
/// abre el marcador vacío y sugiere guardarlo.
Future<void> callMother(BuildContext context, String motherName) async {
  final phone = context.read<SessionStore>().motherPhone;
  final messenger = ScaffoldMessenger.of(context);

  if (phone == null) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Guarda el teléfono de $motherName en Perfil para llamarla con un '
          'toque.',
        ),
      ),
    );
  }

  final opened = await openDialer(phone);
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el teléfono.')),
    );
  }
}

Future<void> callEmergency(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await openDialer(emergencyNumber);
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el teléfono.')),
    );
  }
}
