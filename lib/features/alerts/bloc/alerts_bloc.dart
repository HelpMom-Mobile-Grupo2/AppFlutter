import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api_exception.dart';
import '../data/alert_model.dart';
import '../data/alerts_repository.dart';

part 'alerts_event.dart';
part 'alerts_state.dart';

/// Bloc compartido por Inicio y Alertas. Hace polling cada 15 s mientras una
/// de esas pestañas está visible y la app está en primer plano.
class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  AlertsBloc({
    required AlertsRepository alertsRepository,
    bool Function()? pollingEnabled,
    this.pollInterval = const Duration(seconds: 15),
  }) : _repository = alertsRepository,
       _pollingEnabled = pollingEnabled ?? (() => true),
       super(const AlertsState()) {
    on<AlertsVisibilityChanged>(_onVisibilityChanged);
    on<AlertsRefreshRequested>(_onRefreshRequested);
    on<_AlertsPollTicked>(_onPollTicked);
    on<AlertResponded>(_onAlertResponded);
  }

  /// Recarga [view] y termina cuando llega la respuesta (pull-to-refresh).
  Future<void> refresh(AlertsView view) {
    final completer = Completer<void>();
    add(AlertsRefreshRequested(view, completer: completer));
    return completer.future;
  }

  final AlertsRepository _repository;

  /// Toggle "alertas" de Perfil: en false no hay polling.
  final bool Function() _pollingEnabled;
  final Duration pollInterval;

  AlertsView? _visibleView;
  Timer? _pollTimer;

  /// Alertas con una respuesta en camino: el polling no las pisa.
  final _respondingIds = <String>{};

  Future<void> _onVisibilityChanged(
    AlertsVisibilityChanged event,
    Emitter<AlertsState> emit,
  ) async {
    _visibleView = event.view;
    _pollTimer?.cancel();
    _pollTimer = null;

    final view = event.view;
    if (view == null) return;

    if (_pollingEnabled()) {
      _pollTimer = Timer.periodic(
        pollInterval,
        (_) => add(const _AlertsPollTicked()),
      );
    }
    await _load(view, emit, silent: _hasData(view));
  }

  Future<void> _onRefreshRequested(
    AlertsRefreshRequested event,
    Emitter<AlertsState> emit,
  ) async {
    try {
      await _load(event.view, emit, silent: _hasData(event.view));
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _onPollTicked(
    _AlertsPollTicked event,
    Emitter<AlertsState> emit,
  ) async {
    final view = _visibleView;
    if (view != null) await _load(view, emit, silent: true);
  }

  /// [silent]: ya hay datos en pantalla, así que no se muestra "cargando" y
  /// un error no los reemplaza.
  Future<void> _load(
    AlertsView view,
    Emitter<AlertsState> emit, {
    required bool silent,
  }) async {
    if (!silent) emit(_withStatus(view, LoadStatus.loading));

    try {
      final alerts = view == AlertsView.home
          ? await _repository.fetchPending()
          : await _repository.fetchAll();
      emit(_withAlerts(view, _keepResponding(alerts), isOffline: false));
    } on NotLinkedException {
      emit(state.copyWith(notLinked: true));
    } on UnauthorizedException {
      // El ApiClient ya llevó al login.
    } on ApiException catch (e) {
      if (silent) return;
      emit(_withStatus(view, LoadStatus.failure, errorMessage: e.message));
    } on NoConnectionException {
      final cached = await _repository.cachedAlerts();
      final alerts = view == AlertsView.home
          ? cached.where((alert) => alert.isPending).toList()
          : cached;
      emit(_withAlerts(view, alerts, isOffline: true));
    }
  }

  Future<void> _onAlertResponded(
    AlertResponded event,
    Emitter<AlertsState> emit,
  ) async {
    final original = _findAlert(event.alertId);
    if (original == null ||
        !original.isPending ||
        _respondingIds.contains(original.id)) {
      return;
    }

    // Optimista: la tarjeta pasa a "respondida" antes de que conteste el
    // backend.
    _respondingIds.add(original.id);
    emit(_withAlert(original.respondedWith(event.response, DateTime.now())));

    try {
      final updated = await _repository.respond(original.id, event.response);
      emit(_withAlert(updated));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Ya estaba respondida: cuenta como éxito y se recarga la lista.
        _respondingIds.remove(original.id);
        await _load(_visibleView ?? AlertsView.home, emit, silent: true);
      } else {
        emit(_withAlert(original, actionError: e.message));
      }
    } on NoConnectionException catch (e) {
      emit(_withAlert(original, actionError: e.message));
    } finally {
      _respondingIds.remove(original.id);
    }
  }

  bool _hasData(AlertsView view) =>
      (view == AlertsView.home ? state.homeStatus : state.inboxStatus) ==
      LoadStatus.success;

  QuickAlert? _findAlert(String id) {
    for (final alert in [...state.pending, ...state.all]) {
      if (alert.id == id) return alert;
    }
    return null;
  }

  /// Si una alerta se está respondiendo, se queda la versión local.
  List<QuickAlert> _keepResponding(List<QuickAlert> fetched) => [
    for (final alert in fetched)
      _respondingIds.contains(alert.id) ? _findAlert(alert.id) ?? alert : alert,
  ];

  AlertsState _withStatus(
    AlertsView view,
    LoadStatus status, {
    String? errorMessage,
  }) {
    return view == AlertsView.home
        ? state.copyWith(homeStatus: status, errorMessage: errorMessage)
        : state.copyWith(inboxStatus: status, errorMessage: errorMessage);
  }

  AlertsState _withAlerts(
    AlertsView view,
    List<QuickAlert> alerts, {
    required bool isOffline,
  }) {
    return view == AlertsView.home
        ? state.copyWith(
            pending: alerts,
            homeStatus: LoadStatus.success,
            isOffline: isOffline,
          )
        : state.copyWith(
            all: alerts,
            inboxStatus: LoadStatus.success,
            isOffline: isOffline,
          );
  }

  /// Reemplaza la alerta en las dos listas.
  AlertsState _withAlert(QuickAlert alert, {String? actionError}) {
    List<QuickAlert> replace(List<QuickAlert> list) => [
      for (final item in list) item.id == alert.id ? alert : item,
    ];
    return state.copyWith(
      pending: replace(state.pending),
      all: replace(state.all),
      actionError: actionError,
    );
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
