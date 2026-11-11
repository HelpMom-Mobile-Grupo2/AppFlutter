import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api_exception.dart';
import '../data/companion_repository.dart';
import '../data/daily_tip.dart';

part 'tips_state.dart';

/// Tips del día ("Misión de apoyo"). Lo comparten Inicio y Guía.
class TipsCubit extends Cubit<TipsState> {
  TipsCubit(this._repository) : super(const TipsInitial());

  final CompanionRepository _repository;

  Future<void> load() async {
    final hadData = state is TipsLoaded;
    if (!hadData) emit(const TipsLoading());

    try {
      emit(TipsLoaded(await _repository.getTodayTips()));
    } on NotLinkedException {
      emit(const TipsNotLinked());
    } on UnauthorizedException {
      // El ApiClient ya llevó al login.
    } on ApiException catch (e) {
      if (!hadData) emit(TipsFailure(e.message));
    } on NoConnectionException catch (e) {
      final cached = await _repository.cachedTips();
      if (cached.isNotEmpty) {
        emit(TipsLoaded(cached, isOffline: true));
      } else if (!hadData) {
        emit(TipsFailure(e.message, isOffline: true));
      }
    }
  }

  /// Marca o desmarca el tip (por si se marcó por error). El cambio se ve al
  /// instante y se revierte si el backend falla.
  Future<void> toggle(String tipId) async {
    final current = state;
    if (current is! TipsLoaded) return;
    final tip = current.tips.where((t) => t.id == tipId).firstOrNull;
    if (tip == null) return;

    final wasDone = tip.done;
    emit(_withDone(current, tipId, done: !wasDone));
    try {
      if (wasDone) {
        await _repository.unmarkTipDone(tipId);
      } else {
        await _repository.markTipDone(tipId);
      }
    } on ApiException catch (e) {
      _revert(tipId, wasDone, e.message);
    } on NoConnectionException catch (e) {
      _revert(tipId, wasDone, e.message);
    }
  }

  void _revert(String tipId, bool done, String message) {
    final current = state;
    if (current is TipsLoaded) {
      emit(_withDone(current, tipId, done: done, actionError: message));
    }
  }

  TipsLoaded _withDone(
    TipsLoaded current,
    String tipId, {
    required bool done,
    String? actionError,
  }) {
    return TipsLoaded(
      [
        for (final tip in current.tips)
          tip.id == tipId ? tip.copyWith(done: done) : tip,
      ],
      isOffline: current.isOffline,
      actionError: actionError,
    );
  }
}
