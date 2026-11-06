import '../../../core/local_db.dart';
import 'alert_model.dart';
import 'alerts_api.dart';

/// Alertas del grupo familiar. La lista completa se guarda en sqflite para
/// mostrarla sin conexión.
class AlertsRepository {
  AlertsRepository({required this.api, required this.localDb});

  final AlertsApi api;
  final LocalDb localDb;

  /// Todas las alertas (bandeja). Reemplaza la caché.
  Future<List<QuickAlert>> fetchAll() async {
    final alerts = _newestFirst(await api.getAlerts());
    await localDb.replaceAll(LocalDb.alertsTable, alerts.map(_toRow).toList());
    return alerts;
  }

  /// Solo las pendientes (Inicio). No toca la caché, que guarda todas.
  Future<List<QuickAlert>> fetchPending() async =>
      _newestFirst(await api.getAlerts(pendingOnly: true));

  Future<List<QuickAlert>> cachedAlerts() async {
    final rows = await localDb.queryAll(
      LocalDb.alertsTable,
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<QuickAlert> respond(String alertId, AlertResponse response) async {
    final updated = await api.respond(alertId, response);
    await localDb.update(LocalDb.alertsTable, alertId, _toRow(updated));
    return updated;
  }

  /// Ordena comparando las fechas, no el texto (D.11).
  List<QuickAlert> _newestFirst(List<QuickAlert> alerts) =>
      [...alerts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Map<String, Object?> _toRow(QuickAlert alert) => {
    'id': alert.id,
    'type': alert.type.value,
    'message': alert.message,
    'created_at': alert.createdAt.millisecondsSinceEpoch,
    'status': alert.status.value,
    'response': alert.response?.value,
    'responded_at': alert.respondedAt?.millisecondsSinceEpoch,
  };

  QuickAlert _fromRow(Map<String, Object?> row) {
    final response = row['response'] as int?;
    final respondedAt = row['responded_at'] as int?;
    return QuickAlert(
      id: row['id'] as String,
      type: AlertType.fromValue(row['type'] as int),
      message: row['message'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row['created_at'] as int,
        isUtc: true,
      ),
      status: AlertStatus.fromValue(row['status'] as int),
      response: response == null ? null : AlertResponse.fromValue(response),
      respondedAt: respondedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(respondedAt, isUtc: true),
    );
  }
}
