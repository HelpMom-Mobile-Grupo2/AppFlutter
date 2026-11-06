part of 'summary_cubit.dart';

sealed class SummaryState extends Equatable {
  const SummaryState();

  @override
  List<Object?> get props => [];
}

final class SummaryInitial extends SummaryState {
  const SummaryInitial();
}

final class SummaryLoading extends SummaryState {
  const SummaryLoading();
}

final class SummaryLoaded extends SummaryState {
  const SummaryLoaded(this.summary);

  final CompanionSummary summary;

  @override
  List<Object?> get props => [summary];
}

final class SummaryFailure extends SummaryState {
  const SummaryFailure(this.message, {this.isOffline = false});

  final String message;
  final bool isOffline;

  @override
  List<Object?> get props => [message, isOffline];
}

final class SummaryNotLinked extends SummaryState {
  const SummaryNotLinked();
}
