import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

/// Contenido de una semana de la guía (assets/weekly_guide.json).
class WeekGuide extends Equatable {
  const WeekGuide({
    required this.week,
    required this.baby,
    required this.mother,
    required this.howToHelp,
    required this.preparations,
  });

  factory WeekGuide.fromJson(Map<String, dynamic> json) {
    return WeekGuide(
      week: json['week'] as int,
      baby: json['baby'] as String,
      mother: json['mother'] as String,
      howToHelp: json['howToHelp'] as String,
      preparations: json['preparations'] as String,
    );
  }

  final int week;
  final String baby;
  final String mother;
  final String howToHelp;
  final String preparations;

  /// 1: semanas 1 a 13; 2: semanas 14 a 27; 3: desde la 28.
  int get trimester => week <= 13 ? 1 : (week <= 27 ? 2 : 3);

  String get imageAsset => 'assets/images/trimester_$trimester.png';

  Map<String, dynamic> toJson() => {
    'week': week,
    'baby': baby,
    'mother': mother,
    'howToHelp': howToHelp,
    'preparations': preparations,
  };

  @override
  List<Object?> get props => [week, baby, mother, howToHelp, preparations];
}

/// Guía completa, ordenada por semana.
class WeeklyGuide {
  WeeklyGuide(List<WeekGuide> weeks)
    : weeks = [...weeks]..sort((a, b) => a.week.compareTo(b.week));

  static const assetPath = 'assets/weekly_guide.json';

  static Future<WeeklyGuide> load(AssetBundle bundle) async {
    final json =
        jsonDecode(await bundle.loadString(assetPath)) as Map<String, dynamic>;
    return WeeklyGuide(
      (json['weeks'] as List)
          .map((week) => WeekGuide.fromJson(week as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<WeekGuide> weeks;

  int get firstWeek => weeks.first.week;
  int get lastWeek => weeks.last.week;

  /// La semana pedida o, si está fuera del rango, la más cercana.
  WeekGuide forWeek(int week) {
    final clamped = week.clamp(firstWeek, lastWeek);
    return weeks.firstWhere(
      (guide) => guide.week == clamped,
      orElse: () => weeks.reduce(
        (a, b) => (a.week - clamped).abs() <= (b.week - clamped).abs() ? a : b,
      ),
    );
  }
}
