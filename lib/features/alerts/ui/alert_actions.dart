import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/phone_launcher.dart';
import '../../../core/session_store.dart';
import '../bloc/alerts_bloc.dart';
import '../data/alert_model.dart';

/// Envía la respuesta al AlertsBloc. Con "Te llamo ahora" además abre el
/// marcador con el teléfono de la madre, si está guardado en Perfil.
void respondToAlert(
  BuildContext context,
  String alertId,
  AlertResponse response,
) {
  context.read<AlertsBloc>().add(AlertResponded(alertId, response));

  if (response == AlertResponse.callingNow) {
    final phone = context.read<SessionStore>().motherPhone;
    if (phone != null) openDialer(phone);
  }
}
