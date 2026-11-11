import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/core/api_exception.dart';
import 'package:helpmom_companion/features/companion/cubit/tips_cubit.dart';

import '../support/fake_companion_repository.dart';

void main() {
  late FakeCompanionRepository repository;
  late TipsCubit cubit;

  setUp(() async {
    // sampleTips: t1 y t2 sin hacer, t3 hecho.
    repository = FakeCompanionRepository();
    cubit = TipsCubit(repository);
    await cubit.load();
  });

  tearDown(() => cubit.close());

  bool doneOf(String tipId) =>
      (cubit.state as TipsLoaded).tips.firstWhere((t) => t.id == tipId).done;

  test('marcar: un tip sin hacer llama a POST y queda hecho', () async {
    await cubit.toggle('t1');

    expect(repository.markCalls, ['t1']);
    expect(repository.unmarkCalls, isEmpty);
    expect(doneOf('t1'), isTrue);
    expect((cubit.state as TipsLoaded).actionError, isNull);
  });

  test('desmarcar: un tip hecho llama a DELETE y queda sin hacer', () async {
    await cubit.toggle('t3');

    expect(repository.unmarkCalls, ['t3']);
    expect(repository.markCalls, isEmpty);
    expect(doneOf('t3'), isFalse);
  });

  test('el cambio se ve al instante, antes de que responda el backend', () {
    // Sin await: revisamos el estado justo después de llamar.
    cubit.toggle('t1');

    expect(doneOf('t1'), isTrue);
  });

  test('si falla al marcar, se revierte y avisa', () async {
    repository.markDoneError = const ApiException(
      statusCode: 500,
      message: 'El servidor tuvo un problema.',
    );

    await cubit.toggle('t1');

    expect(doneOf('t1'), isFalse);
    expect(
      (cubit.state as TipsLoaded).actionError,
      'El servidor tuvo un problema.',
    );
  });

  test('si falla al desmarcar (sin internet), vuelve a quedar hecho', () async {
    repository.unmarkDoneError = const NoConnectionException();

    await cubit.toggle('t3');

    expect(doneOf('t3'), isTrue);
    expect((cubit.state as TipsLoaded).actionError, isNotNull);
  });
}
