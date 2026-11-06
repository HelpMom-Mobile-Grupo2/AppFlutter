import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Base local con sqflite. Es solo una caché para ver alertas y tips sin
/// conexión: la fuente de la verdad es siempre el backend.
class LocalDb {
  LocalDb({this.fileName = 'helpmom_companion.db'});

  static const alertsTable = 'alerts';
  static const tipsTable = 'tips';

  final String fileName;
  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      join(dir, fileName),
      version: 1,
      onCreate: (db, version) async {
        // Las fechas se guardan en milisegundos UTC (INTEGER) para ordenarlas
        // por su valor y no por el texto (D.11 del contrato).
        await db.execute('''
          CREATE TABLE $alertsTable (
            id TEXT PRIMARY KEY,
            type INTEGER NOT NULL,
            message TEXT,
            created_at INTEGER NOT NULL,
            status INTEGER NOT NULL,
            response INTEGER,
            responded_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE $tipsTable (
            id TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            done INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Reemplaza todas las filas de [table] por lo último que llegó de la API.
  Future<void> replaceAll(String table, List<Map<String, Object?>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(table);
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(table, row);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, Object?>>> queryAll(
    String table, {
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(table, orderBy: orderBy);
  }

  Future<void> update(
    String table,
    String id,
    Map<String, Object?> values,
  ) async {
    final db = await database;
    await db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  /// Vacía todas las tablas (al cerrar sesión o si el token vence).
  Future<void> clear() async {
    final db = await database;
    await db.delete(alertsTable);
    await db.delete(tipsTable);
  }
}
