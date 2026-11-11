part of 'tips_cubit.dart';

sealed class TipsState extends Equatable {
  const TipsState();

  @override
  List<Object?> get props => [];
}

final class TipsInitial extends TipsState {
  const TipsInitial();
}

final class TipsLoading extends TipsState {
  const TipsLoading();
}

final class TipsLoaded extends TipsState {
  const TipsLoaded(this.tips, {this.isOffline = false, this.actionError});

  final List<DailyTip> tips;

  /// true si los tips vienen de sqflite porque no hay internet.
  final bool isOffline;

  /// Error al marcar o desmarcar un tip: se muestra una sola vez (SnackBar).
  final String? actionError;

  @override
  List<Object?> get props => [tips, isOffline, actionError];
}

final class TipsFailure extends TipsState {
  const TipsFailure(this.message, {this.isOffline = false});

  final String message;
  final bool isOffline;

  @override
  List<Object?> get props => [message, isOffline];
}

final class TipsNotLinked extends TipsState {
  const TipsNotLinked();
}
