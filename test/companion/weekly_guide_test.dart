import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpmom_companion/features/companion/data/weekly_guide.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WeeklyGuide guide;

  setUpAll(() async => guide = await WeeklyGuide.load(rootBundle));

  test('trae una entrada por semana, de la 4 a la 41, sin huecos', () {
    expect(guide.firstWeek, 4);
    expect(guide.lastWeek, 41);
    expect(guide.weeks.map((w) => w.week), [
      for (var week = 4; week <= 41; week++) week,
    ]);
  });

  test('cada semana tiene los cuatro textos', () {
    for (final week in guide.weeks) {
      expect(week.baby, isNotEmpty, reason: 'semana ${week.week}');
      expect(week.mother, isNotEmpty, reason: 'semana ${week.week}');
      expect(week.howToHelp, isNotEmpty, reason: 'semana ${week.week}');
      expect(week.preparations, isNotEmpty, reason: 'semana ${week.week}');
    }
  });

  test('no incluye valores clínicos (unidades de medida)', () {
    final clinical = RegExp(r'\b(lpm|bpm|°C|mmHg|kg|cm|gramos)\b');
    for (final week in guide.weeks) {
      final text = [
        week.baby,
        week.mother,
        week.howToHelp,
        week.preparations,
      ].join(' ');
      expect(clinical.hasMatch(text), isFalse, reason: 'semana ${week.week}');
    }
  });

  test('forWeek usa la semana más cercana fuera del rango', () {
    expect(guide.forWeek(2).week, 4);
    expect(guide.forWeek(25).week, 25);
    expect(guide.forWeek(45).week, 41);
  });

  test('la ilustración depende del trimestre y existe en assets', () async {
    expect(guide.forWeek(13).imageAsset, 'assets/images/trimester_1.png');
    expect(guide.forWeek(14).imageAsset, 'assets/images/trimester_2.png');
    expect(guide.forWeek(28).imageAsset, 'assets/images/trimester_3.png');

    for (final trimester in [1, 2, 3]) {
      final data = await rootBundle.load(
        'assets/images/trimester_$trimester.png',
      );
      expect(data.lengthInBytes, greaterThan(0));
    }
  });

  test('WeekGuide.fromJson/toJson', () {
    final week = guide.forWeek(25);

    expect(WeekGuide.fromJson(week.toJson()), week);
  });
}
