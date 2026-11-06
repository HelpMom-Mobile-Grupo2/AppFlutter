import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api_exception.dart';
import '../data/companion_repository.dart';
import '../data/companion_summary.dart';

part 'summary_state.dart';

/// Estado resumido de la madre: semáforo, mensaje y semana.
class SummaryCubit extends Cubit<SummaryState> {
  SummaryCubit(this._repository) : super(const SummaryInitial());

  final CompanionRepository _repository;

  /// Si ya hay un resumen en pantalla, un error no lo reemplaza.
  Future<void> load() async {
    final hadData = state is SummaryLoaded;
    if (!hadData) emit(const SummaryLoading());

    try {
      emit(SummaryLoaded(await _repository.getSummary()));
    } on NotLinkedException {
      emit(const SummaryNotLinked());
    } on UnauthorizedException {
      // El ApiClient ya llevó al login.
    } on ApiException catch (e) {
      if (!hadData) emit(SummaryFailure(e.message));
    } on NoConnectionException catch (e) {
      if (!hadData) emit(SummaryFailure(e.message, isOffline: true));
    }
  }
}
