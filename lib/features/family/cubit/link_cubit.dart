import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api_exception.dart';
import '../data/family_repository.dart';

part 'link_state.dart';

/// Vincula al acompañante con la gestante usando el código de invitación.
class LinkCubit extends Cubit<LinkState> {
  LinkCubit(this._repository) : super(const LinkInitial());

  final FamilyRepository _repository;

  Future<void> join(String code) async {
    emit(const LinkLoading());
    try {
      final result = await _repository.join(code);
      emit(LinkSuccess(result.motherName));
    } on ApiException catch (e) {
      // 404: código inexistente. 409 y 400: el detail del backend.
      emit(
        LinkFailure(e.statusCode == 404 ? 'Ese código no existe' : e.message),
      );
    } on NoConnectionException catch (e) {
      emit(LinkFailure(e.message));
    }
  }
}
