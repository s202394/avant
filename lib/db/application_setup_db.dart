import 'package:avant/model/login_model.dart';
import 'package:avant/model/menu_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initializeDB();
    return _database!;
  }
//Initialize the Database
  Future<Database> initializeDB() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'avant_database.db'),
      onCreate: (database, version) async {
        /*await database.execute(
        "CREATE TABLE executiveData(userId INTEGER PRIMARY KEY, executiveId INTEGER, executiveName TEXT, executiveEmail TEXT)",
      );*/
        await database.execute(
          "CREATE TABLE applicationSetup(key TEXT PRIMARY KEY, keyValue TEXT)",
        );
        print("applicationSetup table successfully created.");
        await database.execute(
          "CREATE TABLE menuData(MenuName TEXT, ChildMenuName TEXT, LinkURL TEXT)",
        );
        print("menuData table successfully created.");
      },
      version: 1,
    );
  }

//Clear the Database
  Future<void> clearDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'avant_database.db');
    Database database = await openDatabase(path);
    // Get the list of all tables
    List<Map<String, dynamic>> tables = await database
        .rawQuery('SELECT name FROM sqlite_master WHERE type = "table"');

    // Iterate through the tables and delete all data
    for (var table in tables) {
      var tableName = table['name'];
      if (tableName != 'android_metadata' && tableName != 'sqlite_sequence') {
        await database.delete(tableName);
      }
    }
  }

//Save tExecutive Data to the Database
/*Future<void> insertExecutiveData(ExecutiveData data) async {
  final db = await initializeDB();
  await db.insert('executiveData', data.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
}*/

//Save ApplicationSetup Data to the Database
  Future<void> insertApplicationSetup(ApplicationSetup data) async {
    final db = await database;
    await db.insert('applicationSetup', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    print("${data.key}:${data.keyValue} successfully inserted into db.");
  }

//Retrieve Executive Data from the Database
/*Future<List<ExecutiveData>> getExecutiveDataFromDB() async {
  final db = await initializeDB();
  final List<Map<String, dynamic>> maps = await db.query('executiveData');
  return List.generate(maps.length, (i) {
    return ExecutiveData.fromJson(maps[i]);
  });
}*/

//Retrieve ApplicationSetup Data from the Database
  Future<List<ApplicationSetup>> getApplicationSetupFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('applicationSetup');
    return List.generate(maps.length, (i) {
      return ApplicationSetup.fromJson(maps[i]);
    });
  }

//Save Menu Data to the Database
  Future<void> insertMenuData(MenuData data) async {
    final db = await database;
    await db.insert('menuData', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    print('Inserting into DB: ${data.toJson()}');
    print(
        "${data.menuName}:${data.childMenuName} successfully inserted into db.");
  }

//Retrieve ApplicationSetup Data from the Database
  Future<List<MenuData>> getMenuDataFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('menuData');
    print("Getting menu data from db.");
    for (var map in maps) {
      print('Raw data from DB: ${map}');
    }
    return List.generate(maps.length, (i) {
      final menuData = MenuData.fromJson(maps[i]);
      print('Parsed MenuData: ${menuData.toJson()}');
      return menuData;
    });
  }

  Future<void> checkMenuData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('menuData');
    print("Menu Data from DB:");
    for (var map in maps) {
      print(map);
    }
  }

  Future<void> clearMenuDataDatabase() async {
    final db = await database;
    await db.delete('menuData');
    print("Menu Data successfully deleted.");
  }
}