import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/session_store.dart';

part 'profile_state.dart';

/// Datos del acompañante y preferencias guardadas en shared_preferences.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._session) : super(_read(_session));

  final SessionStore _session;

  static ProfileState _read(SessionStore session) => ProfileState(
    fullName: session.fullName ?? '',
    email: session.email ?? '',
    motherPhone: session.motherPhone,
    dailyTipNotifications: session.dailyTipNotifications,
    alertNotifications: session.alertNotifications,
  );

  Future<void> setDailyTipNotifications(bool enabled) async {
    await _session.setDailyTipNotifications(enabled);
    emit(_read(_session));
  }

  Future<void> setAlertNotifications(bool enabled) async {
    await _session.setAlertNotifications(enabled);
    emit(_read(_session));
  }

  /// null o vacío borra el teléfono.
  Future<void> setMotherPhone(String? phone) async {
    await _session.setMotherPhone(phone);
    emit(_read(_session));
  }
}
