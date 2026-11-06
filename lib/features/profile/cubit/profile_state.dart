part of 'profile_cubit.dart';

final class ProfileState extends Equatable {
  const ProfileState({
    required this.fullName,
    required this.email,
    required this.dailyTipNotifications,
    required this.alertNotifications,
    this.motherPhone,
  });

  final String fullName;
  final String email;

  /// Teléfono de la madre guardado en el teléfono (el backend no lo tiene).
  final String? motherPhone;
  final bool dailyTipNotifications;

  /// Si está apagado, no hay polling de alertas.
  final bool alertNotifications;

  @override
  List<Object?> get props => [
    fullName,
    email,
    motherPhone,
    dailyTipNotifications,
    alertNotifications,
  ];
}
