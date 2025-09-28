import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'suvai.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE recipes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        imagePath TEXT,
        servings INTEGER NOT NULL,
        prepTimeMinutes INTEGER NOT NULL, 
        cookTimeMinutes INTEGER NOT NULL,
        instructions TEXT NOT NULL,
        tags TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ingredients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipeId INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        preparation TEXT,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE meal_plan(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        mealType TEXT NOT NULL,
        recipeId INTEGER NOT NULL,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE
      )
      ''');
  }
}