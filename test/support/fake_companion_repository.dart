import 'package:helpmom_companion/features/companion/data/companion_repository.dart';
import 'package:helpmom_companion/features/companion/data/companion_summary.dart';
import 'package:helpmom_companion/features/companion/data/daily_tip.dart';

const sampleSummary = CompanionSummary(
  motherName: 'Daniela Gómez',
  gestationalWeeks: 25,
  gestationalDays: 1,
  healthLight: HealthLight.green,
  healthSummary: 'Valores dentro del rango de referencia simulado.',
);

const sampleTips = [
  DailyTip(
    id: 't1',
    title: 'Evita que cargue peso o paquetes',
    body: 'Desde el segundo trimestre...',
    done: false,
  ),
  DailyTip(
    id: 't2',
    title: 'Prepara una cena ligera',
    body: 'Algo simple y nutritivo.',
    done: false,
  ),
  DailyTip(
    id: 't3',
    title: 'Pregúntale cómo se siente',
    body: 'Escucha sin juzgar.',
    done: true,
  ),
];

/// Repositorio de prueba con datos en memoria.
class FakeCompanionRepository implements CompanionRepository {
  FakeCompanionRepository({
    this.summary = sampleSummary,
    List<DailyTip> tips = sampleTips,
  }) : tips = [...tips];

  CompanionSummary summary;
  List<DailyTip> tips;
  List<DailyTip> cached = [];
  Object? error;
  Object? markDoneError;

  @override
  Future<CompanionSummary> getSummary() async {
    if (error != null) throw error!;
    return summary;
  }

  @override
  Future<List<DailyTip>> getTodayTips() async {
    if (error != null) throw error!;
    return [...tips];
  }

  @override
  Future<List<DailyTip>> cachedTips() async => [...cached];

  @override
  Future<void> markTipDone(String tipId) async {
    if (markDoneError != null) throw markDoneError!;
    tips = [
      for (final tip in tips) tip.id == tipId ? tip.copyWith(done: true) : tip,
    ];
  }
}
