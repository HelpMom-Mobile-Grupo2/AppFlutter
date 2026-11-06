part of 'link_cubit.dart';

sealed class LinkState extends Equatable {
  const LinkState();

  @override
  List<Object?> get props => [];
}

final class LinkInitial extends LinkState {
  const LinkInitial();
}

final class LinkLoading extends LinkState {
  const LinkLoading();
}

final class LinkSuccess extends LinkState {
  const LinkSuccess(this.motherName);

  final String motherName;

  @override
  List<Object?> get props => [motherName];
}

final class LinkFailure extends LinkState {
  const LinkFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
