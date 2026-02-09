// lib/database/database_provider.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/calculation_history.dart';

class DatabaseProvider {
  static final DatabaseProvider instance = DatabaseProvider._init();
  static Database? _database;

  DatabaseProvider._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'calculations.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE calculations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        a REAL NOT NULL,
        b REAL NOT NULL,
        c REAL NOT NULL,
        equation TEXT NOT NULL,
        discriminant TEXT NOT NULL,
        message TEXT NOT NULL,
        roots TEXT NOT NULL,
        type TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // Добавление расчета
  Future<int> insertCalculation(CalculationHistory calculation) async {
    final db = await database;
    return await db.insert('calculations', calculation.toMap());
  }

  // Получение всех расчетов
  Future<List<CalculationHistory>> getAllCalculations() async {
    final db = await database;
    final maps = await db.query('calculations', orderBy: 'timestamp DESC');
    return maps.map((map) => CalculationHistory.fromMap(map)).toList();
  }

  // Получение расчета по ID
  Future<CalculationHistory?> getCalculation(int id) async {
    final db = await database;
    final maps = await db.query(
      'calculations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CalculationHistory.fromMap(maps.first);
    }
    return null;
  }

  // Удаление расчета по ID
  Future<int> deleteCalculation(int id) async {
    final db = await database;
    return await db.delete(
      'calculations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Обновление расчета
  Future<int> updateCalculation(CalculationHistory calculation) async {
    final db = await database;
    return await db.update(
      'calculations',
      calculation.toMap(),
      where: 'id = ?',
      whereArgs: [calculation.id],
    );
  }

  // Очистка всей истории
  Future<int> clearAllCalculations() async {
    final db = await database;
    return await db.delete('calculations');
  }

  // Закрытие базы данных
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}