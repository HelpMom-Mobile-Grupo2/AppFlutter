import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/api_exception.dart';
import 'package:helpmom_companion/features/alerts/bloc/alerts_bloc.dart';
import 'package:helpmom_companion/features/alerts/data/alert_model.dart';

import '../support/fake_alerts_repository.dart';

void main() {
  late FakeAlertsRepository repository;
  late AlertsBloc bloc;

  final pending = buildAlert(id: 'a1', minutesAgo: 2);
  final older = buildAlert(
    id: 'a0',
    minutesAgo: 60,
    status: AlertStatus.responded,
    response: AlertResponse.done,
  );

  setUp(() {
    repository = FakeAlertsRepository(alerts: [pending, older]);
    bloc = AlertsBloc(
      alertsRepository: repository,
      pollInterval: const Duration(hours: 1),
    );
  });

  tearDown(() => bloc.close());

  /// Carga Inicio y espera a que termine.
  Future<void> loadHome() async {
    final loaded = bloc.stream.firstWhere(
      (state) => state.homeStatus == LoadStatus.success,
    );
    bloc.add(const AlertsVisibilityChanged(AlertsView.home));
    await loaded;
  }

  test(
    'cargar: Inicio pide las pendientes y muestra la más reciente',
    () async {
      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const AlertsState(homeStatus: LoadStatus.loading),
          AlertsState(pending: [pending], homeStatus: LoadStatus.success),
        ]),
      );
      bloc.add(const AlertsVisibilityChanged(AlertsView.home));
      await expectation;

      expect(repository.fetchPendingCalls, 1);
      expect(bloc.state.activeAlert, pending);
    },
  );

  test(
    'responder con éxito: optimista y luego la versión del servidor',
    () async {
      await loadHome();

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          // Optimista: ya respondida, con la respuesta elegida.
          predicate<AlertsState>(
            (state) =>
                state.activeAlert!.status == AlertStatus.responded &&
                state.activeAlert!.response == AlertResponse.onMyWay,
          ),
          // Confirmada por el servidor.
          predicate<AlertsState>(
            (state) =>
                state.activeAlert ==
                    pending.respondedWith(AlertResponse.onMyWay, baseTime) &&
                state.actionError == null,
          ),
        ]),
      );
      bloc.add(AlertResponded(pending.id, AlertResponse.onMyWay));
      await expectation;

      expect(repository.respondCalls, [('a1', AlertResponse.onMyWay)]);
    },
  );

  test('responder con error: revierte la alerta y avisa', () async {
    await loadHome();
    repository.respondError = const ApiException(
      statusCode: 500,
      message: 'El servidor tuvo un problema. Intenta más tarde.',
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        predicate<AlertsState>(
          (state) => state.activeAlert!.status == AlertStatus.responded,
        ),
        predicate<AlertsState>(
          (state) =>
              state.activeAlert == pending &&
              state.actionError ==
                  'El servidor tuvo un problema. Intenta más tarde.',
        ),
      ]),
    );
    bloc.add(AlertResponded(pending.id, AlertResponse.callingNow));
    await expectation;
  });

  test('responder sin internet también revierte', () async {
    await loadHome();
    repository.respondError = const NoConnectionException();

    final reverted = bloc.stream.firstWhere(
      (state) => state.actionError != null,
    );
    bloc.add(AlertResponded(pending.id, AlertResponse.done));

    expect((await reverted).activeAlert, pending);
  });

  test('409 "ya estaba respondida" cuenta como éxito y recarga', () async {
    await loadHome();
    // Otro dispositivo ya la respondió: el backend la tiene respondida.
    repository.alerts = [
      pending.respondedWith(AlertResponse.done, baseTime),
      older,
    ];
    repository.respondError = const ApiException(
      statusCode: 409,
      message: 'La alerta ya fue respondida.',
    );

    final reloaded = bloc.stream.firstWhere((state) => state.pending.isEmpty);
    bloc.add(AlertResponded(pending.id, AlertResponse.onMyWay));
    final state = await reloaded;

    expect(state.actionError, isNull);
    expect(repository.fetchPendingCalls, 2);
  });

  test('409 "no vinculado" marca notLinked', () async {
    repository.fetchError = const NotLinkedException();

    final notLinked = bloc.stream.firstWhere((state) => state.notLinked);
    bloc.add(const AlertsVisibilityChanged(AlertsView.home));

    expect((await notLinked).notLinked, isTrue);
  });

  test('sin internet muestra la caché con isOffline', () async {
    repository
      ..fetchError = const NoConnectionException()
      ..cached = [pending, older];

    final offline = bloc.stream.firstWhere(
      (state) => state.inboxStatus == LoadStatus.success,
    );
    bloc.add(const AlertsVisibilityChanged(AlertsView.inbox));
    final state = await offline;

    expect(state.isOffline, isTrue);
    expect(state.all, [pending, older]);
  });

  test('refresh termina aunque no cambie nada (pull-to-refresh)', () async {
    await loadHome();

    // Mismos datos: el bloc no emite un estado nuevo, pero el Future termina.
    await bloc.refresh(AlertsView.home).timeout(const Duration(seconds: 1));

    expect(repository.fetchPendingCalls, 2);
  });

  group('polling', () {
    late AlertsBloc pollingBloc;

    setUp(() {
      pollingBloc = AlertsBloc(
        alertsRepository: repository,
        pollInterval: const Duration(milliseconds: 20),
      );
    });

    tearDown(() => pollingBloc.close());

    test('corre mientras se ve Alertas y se detiene al ocultarla', () async {
      pollingBloc.add(const AlertsVisibilityChanged(AlertsView.inbox));
      await Future<void>.delayed(const Duration(milliseconds: 110));
      final callsWhileVisible = repository.fetchAllCalls;
      expect(callsWhileVisible, greaterThanOrEqualTo(3));

      pollingBloc.add(const AlertsVisibilityChanged(null));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final callsWhenHidden = repository.fetchAllCalls;
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(repository.fetchAllCalls, callsWhenHidden);
    });

    test('en Inicio el polling pide solo las pendientes', () async {
      pollingBloc.add(const AlertsVisibilityChanged(AlertsView.home));
      await Future<void>.delayed(const Duration(milliseconds: 70));

      expect(repository.fetchPendingCalls, greaterThanOrEqualTo(2));
      expect(repository.fetchAllCalls, 0);
    });

    test('con el toggle de alertas apagado no hay polling', () async {
      final quietBloc = AlertsBloc(
        alertsRepository: repository,
        pollingEnabled: () => false,
        pollInterval: const Duration(milliseconds: 20),
      );
      addTearDown(quietBloc.close);

      quietBloc.add(const AlertsVisibilityChanged(AlertsView.inbox));
      await Future<void>.delayed(const Duration(milliseconds: 90));

      expect(repository.fetchAllCalls, 1);
    });
  });
}
