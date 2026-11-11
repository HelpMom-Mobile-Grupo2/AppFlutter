import '../../../core/local_db.dart';
import 'companion_api.dart';
import 'companion_summary.dart';
import 'daily_tip.dart';

/// Resumen de la madre y tips del día. Los tips se guardan en sqflite para
/// verlos sin conexión.
class CompanionRepository {
  CompanionRepository({required this.api, required this.localDb});

  final CompanionApi api;
  final LocalDb localDb;

  Future<CompanionSummary> getSummary() => api.getSummary();

  Future<List<DailyTip>> getTodayTips() async {
    final tips = await api.getTodayTips();
    await localDb.replaceAll(LocalDb.tipsTable, [
      for (var i = 0; i < tips.length; i++) _toRow(tips[i], i),
    ]);
    return tips;
  }

  Future<List<DailyTip>> cachedTips() async {
    final rows = await localDb.queryAll(LocalDb.tipsTable, orderBy: 'position');
    return rows.map(_fromRow).toList();
  }

  Future<void> markTipDone(String tipId) async {
    await api.markTipDone(tipId);
    await localDb.update(LocalDb.tipsTable, tipId, {'done': 1});
  }

  Future<void> unmarkTipDone(String tipId) async {
    await api.unmarkTipDone(tipId);
    await localDb.update(LocalDb.tipsTable, tipId, {'done': 0});
  }

  Map<String, Object?> _toRow(DailyTip tip, int position) => {
    'id': tip.id,
    'position': position,
    'title': tip.title,
    'body': tip.body,
    'done': tip.done ? 1 : 0,
  };

  DailyTip _fromRow(Map<String, Object?> row) => DailyTip(
    id: row['id'] as String,
    title: row['title'] as String,
    body: row['body'] as String,
    done: row['done'] == 1,
  );
}
