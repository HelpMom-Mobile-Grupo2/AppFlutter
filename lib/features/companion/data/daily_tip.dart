import 'package:equatable/equatable.dart';

class DailyTip extends Equatable {
  const DailyTip({
    required this.id,
    required this.title,
    required this.body,
    required this.done,
  });

  factory DailyTip.fromJson(Map<String, dynamic> json) {
    return DailyTip(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      done: json['done'] as bool,
    );
  }

  final String id;
  final String title;
  final String body;
  final bool done;

  DailyTip copyWith({bool? done}) =>
      DailyTip(id: id, title: title, body: body, done: done ?? this.done);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'done': done,
  };

  @override
  List<Object?> get props => [id, title, body, done];
}
