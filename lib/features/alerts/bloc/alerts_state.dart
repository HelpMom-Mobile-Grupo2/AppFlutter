part of 'alerts_bloc.dart';

enum LoadStatus { initial, loading, success, failure }

final class AlertsState extends Equatable {
  const AlertsState({
    this.pending = const [],
    this.all = const [],
    this.homeStatus = LoadStatus.initial,
    this.inboxStatus = LoadStatus.initial,
    this.isOffline = false,
    this.notLinked = false,
    this.errorMessage,
    this.actionError,
    this.newSos,
  });

  /// Respuesta de ?status=pending (Inicio), de la más reciente a la más antigua.
  final List<QuickAlert> pending;

  /// Todas las alertas (bandeja de Alertas).
  final List<QuickAlert> all;

  final LoadStatus homeStatus;
  final LoadStatus inboxStatus;

  /// true si lo que se ve viene de sqflite porque no hay internet.
  final bool isOffline;

  /// El backend respondió 409 "Aún no estás vinculado".
  final bool notLinked;

  /// Mensaje de la última carga fallida.
  final String? errorMessage;

  /// Error al responder una alerta: se muestra una sola vez (SnackBar).
  final String? actionError;

  /// SOS pendiente que acaba de llegar: abre el aviso de pantalla completa.
  /// Viene una sola vez por alerta.
  final QuickAlert? newSos;

  /// La pendiente más reciente: la tarjeta de alerta activa de Inicio.
  QuickAlert? get activeAlert => pending.isEmpty ? null : pending.first;

  /// [actionError] y [newSos] no se conservan: cada estado nuevo los limpia.
  AlertsState copyWith({
    List<QuickAlert>? pending,
    List<QuickAlert>? all,
    LoadStatus? homeStatus,
    LoadStatus? inboxStatus,
    bool? isOffline,
    bool? notLinked,
    String? errorMessage,
    String? actionError,
    QuickAlert? newSos,
  }) {
    return AlertsState(
      pending: pending ?? this.pending,
      all: all ?? this.all,
      homeStatus: homeStatus ?? this.homeStatus,
      inboxStatus: inboxStatus ?? this.inboxStatus,
      isOffline: isOffline ?? this.isOffline,
      notLinked: notLinked ?? this.notLinked,
      errorMessage: errorMessage ?? this.errorMessage,
      actionError: actionError,
      newSos: newSos,
    );
  }

  @override
  List<Object?> get props => [
    pending,
    all,
    homeStatus,
    inboxStatus,
    isOffline,
    notLinked,
    errorMessage,
    actionError,
    newSos,
  ];
}
