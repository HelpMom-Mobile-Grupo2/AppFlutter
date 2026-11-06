part of 'alerts_bloc.dart';

/// Pestaña que muestra alertas: Inicio (solo pendientes) o Alertas (todas).
enum AlertsView { home, inbox }

sealed class AlertsEvent extends Equatable {
  const AlertsEvent();

  @override
  List<Object?> get props => [];
}

/// Cambió la pestaña visible o la app pasó a primer/segundo plano.
/// [view] es null cuando no se ve ninguna pestaña con alertas.
final class AlertsVisibilityChanged extends AlertsEvent {
  const AlertsVisibilityChanged(this.view);

  final AlertsView? view;

  @override
  List<Object?> get props => [view];
}

/// Pull-to-refresh o "Reintentar".
final class AlertsRefreshRequested extends AlertsEvent {
  const AlertsRefreshRequested(this.view, {this.completer});

  final AlertsView view;

  /// Se completa al terminar la carga (lo espera el RefreshIndicator).
  final Completer<void>? completer;

  @override
  List<Object?> get props => [view];
}

final class AlertResponded extends AlertsEvent {
  const AlertResponded(this.alertId, this.response);

  final String alertId;
  final AlertResponse response;

  @override
  List<Object?> get props => [alertId, response];
}

/// Lo dispara el Timer del polling cada 15 s.
final class _AlertsPollTicked extends AlertsEvent {
  const _AlertsPollTicked();
}
