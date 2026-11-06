import '../../../core/local_db.dart';
import 'companion_api.dart';
import 'companion_summary.dart';
import 'daily_tip.dart';

/// Resumen de la madre y tips del día. Los tips se guardan en sqflite para
/// verlos sin conexión.
class CompanionRepository {
  CompanionRepository({required CompanionApi api, required LocalDb localDb})
    : _api = api,
      _localDb = localDb;

  final CompanionApi _api;
  final LocalDb _localDb;

  Future<CompanionSummary> getSummary() => _api.getSummary();

  Future<List<DailyTip>> getTodayTips() async {
    final tips = await _api.getTodayTips();
    await _localDb.replaceAll(LocalDb.tipsTable, [
      for (var i = 0; i < tips.length; i++) _toRow(tips[i], i),
    ]);
    return tips;
  }

  Future<List<DailyTip>> cachedTips() async {
    final rows = await _localDb.queryAll(
      LocalDb.tipsTable,
      orderBy: 'position',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> markTipDone(String tipId) async {
    await _api.markTipDone(tipId);
    await _localDb.update(LocalDb.tipsTable, tipId, {'done': 1});
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
