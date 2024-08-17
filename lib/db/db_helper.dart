import 'package:avant/model/login_model.dart';
import 'package:avant/model/menu_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/model/customer_entry_master_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

abstract class JsonSerializable {
  Map<String, dynamic> toJson();
}

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

        //Start Create tables for each list in the CustomerEntryMasterResponse
        await database.execute(
          "CREATE TABLE BoardMaster(BoardId INTEGER PRIMARY KEY, BoardName TEXT)",
        );
        print("BoardMaster table successfully created.");

        await database.execute(
          "CREATE TABLE Classes(ClassNumId INTEGER PRIMARY KEY, ClassName TEXT)",
        );
        print("Classes table successfully created.");

        await database.execute(
          "CREATE TABLE DataSource(DataSourceId INTEGER PRIMARY KEY, DataSourceName TEXT)",
        );
        print("DataSource table successfully created.");

        await database.execute(
          "CREATE TABLE ChainSchool(ChainSchoolId INTEGER PRIMARY KEY, ChainSchoolName TEXT)",
        );
        print("ChainSchool table successfully created.");

        await database.execute(
          "CREATE TABLE AccountableExecutive(SNo INTEGER PRIMARY KEY, ExecutiveName TEXT)",
        );
        print("AccountableExecutive table successfully created.");

        await database.execute(
          "CREATE TABLE SalutationMaster(SalutationId INTEGER PRIMARY KEY, SalutationName TEXT)",
        );
        print("SalutationMaster table successfully created.");

        await database.execute(
          "CREATE TABLE ContactDesignation(ContactDesignationId INTEGER PRIMARY KEY, ContactDesignationName TEXT)",
        );
        print("ContactDesignation table successfully created.");

        await database.execute(
          "CREATE TABLE Subject(SubjectId INTEGER PRIMARY KEY, SubjectName TEXT)",
        );
        print("Subject table successfully created.");

        await database.execute(
          "CREATE TABLE Department(DepartmentId INTEGER PRIMARY KEY, DepartmentName TEXT)",
        );
        print("Department table successfully created.");

        await database.execute(
          "CREATE TABLE AdoptionRoleMaster(AdoptionRoleId INTEGER PRIMARY KEY, AdoptionRole TEXT)",
        );
        print("AdoptionRoleMaster table successfully created.");

        await database.execute(
          "CREATE TABLE CustomerCategory(CustomerCategoryId INTEGER PRIMARY KEY, CustomerCategoryName TEXT)",
        );
        print("CustomerCategory table successfully created.");

        await database.execute(
          "CREATE TABLE Months(ID TEXT PRIMARY KEY, Name TEXT)",
        );
        print("Months table successfully created.");

        await database.execute(
          "CREATE TABLE PurchaseMode(ModeValue TEXT PRIMARY KEY, ModeName TEXT)",
        );
        print("PurchaseMode table successfully created.");

        await database.execute(
          "CREATE TABLE InstituteType(ID TEXT PRIMARY KEY, InstituteType TEXT)",
        );
        print("InstituteType table successfully created.");

        await database.execute(
          "CREATE TABLE InstituteLevel(ID TEXT PRIMARY KEY, InstituteLevel TEXT)",
        );
        print("InstituteLevel table successfully created.");

        await database.execute(
          "CREATE TABLE AffiliateType(ID TEXT PRIMARY KEY, AffiliateType TEXT)",
        );
        print("AffiliateType table successfully created.");
        // End Create tables for each list in the CustomerEntryMasterResponse

        //Create table for Geography
        await database.execute(
          "CREATE TABLE Geography(CountryId Int, Country TEXT, StateId Int, State TEXT, CityId Int, City TEXT)",
        );
        print("Geography table successfully created.");
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

  //Retrieve Menu Data from the Database
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

// Insert BoardMaster Data into the Database
  Future<void> insertBoardMaster(BoardMaster data) async {
    final db = await database;
    await db.insert('BoardMaster', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    print(
        "BoardMaster ${data.boardId}:${data.boardName} successfully inserted into db.");
  }

  //Retrieve BoardMaster Data from the Database
  Future<List<BoardMaster>> getBoardMasterFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('BoardMaster');
    print("Getting BoardMaster from db.");
    return List.generate(maps.length, (i) {
      final data = BoardMaster.fromJson(maps[i]);
      return data;
    });
  }

// Insert Classes Data into the Database
  Future<void> insertClasses(Classes data) async {
    final db = await database;
    await db.insert('Classes', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //Retrieve Classes Data from the Database
  Future<List<Classes>> getClassesFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Classes');
    print("Getting Classes from db.");
    return List.generate(maps.length, (i) {
      final data = Classes.fromJson(maps[i]);
      return data;
    });
  }

// Insert DataSource Data into the Database
  Future<void> insertDataSource(DataSource data) async {
    final db = await database;
    await db.insert('DataSource', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //Retrieve DataSource Data from the Database
  Future<List<DataSource>> getDataSourceFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('DataSource');
    print("Getting DataSource from db.");
    return List.generate(maps.length, (i) {
      final data = DataSource.fromJson(maps[i]);
      return data;
    });
  }

// Insert ChainSchool Data into the Database
  Future<void> insertChainSchools(ChainSchool data) async {
    final db = await database;
    await db.insert('ChainSchool', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //Retrieve ChainSchool Data from the Database
  Future<List<ChainSchool>> getChainSchoolFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('ChainSchool');
    print("Getting ChainSchool from db.");
    return List.generate(maps.length, (i) {
      final data = ChainSchool.fromJson(maps[i]);
      return data;
    });
  }

// Insert AccountableExecutive Data into the Database
  Future<void> insertAccountableExecutive(AccountableExecutive data) async {
    final db = await database;
    await db.insert('AccountableExecutive', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //Retrieve AccountableExecutive Data from the Database
  Future<List<AccountableExecutive>> getAccountableExecutiveFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('AccountableExecutive');
    print("Getting AccountableExecutive from db.");
    return List.generate(maps.length, (i) {
      final data = AccountableExecutive.fromJson(maps[i]);
      return data;
    });
  }

// Insert SalutationMaster Data into the Database
  Future<void> insertSalutationMaster(SalutationMaster data) async {
    final db = await database;
    await db.insert('SalutationMaster', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //Retrieve SalutationMaster Data from the Database
  Future<List<SalutationMaster>> getSalutationMasterFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('SalutationMaster');
    print("Getting SalutationMaster from db.");
    return List.generate(maps.length, (i) {
      final data = SalutationMaster.fromJson(maps[i]);
      return data;
    });
  }

// Insert ContactDesignation Data into the Database
  Future<void> insertContactDesignation(ContactDesignation data) async {
    final db = await database;
    await db.insert('ContactDesignation', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//Retrieve ContactDesignation Data from the Database
  Future<List<ContactDesignation>> getContactDesignationFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('ContactDesignation');
    print("Getting ContactDesignation from db.");
    return List.generate(maps.length, (i) {
      final data = ContactDesignation.fromJson(maps[i]);
      return data;
    });
  }

// Insert Subject Data into the Database
  Future<void> insertSubject(Subject data) async {
    final db = await database;
    await db.insert('Subject', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//Retrieve Subject Data from the Database
  Future<List<Subject>> getSubjectFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Subject');
    print("Getting Subject from db.");
    return List.generate(maps.length, (i) {
      final data = Subject.fromJson(maps[i]);
      return data;
    });
  }

// Insert Department Data into the Database
  Future<void> insertDepartment(Department data) async {
    final db = await database;
    await db.insert('Department', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//Retrieve Department Data from the Database
  Future<List<Department>> getDepartmentFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Department');
    print("Getting Department from db.");
    return List.generate(maps.length, (i) {
      final data = Department.fromJson(maps[i]);
      return data;
    });
  }

// Insert AdoptionRoleMaster Data into the Database
  Future<void> insertAdoptionRoleMaster(AdoptionRoleMaster data) async {
    final db = await database;
    await db.insert('AdoptionRoleMaster', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//Retrieve AdoptionRoleMaster Data from the Database
  Future<List<AdoptionRoleMaster>> getAdoptionRoleMasterFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('AdoptionRoleMaster');
    print("Getting AdoptionRoleMaster from db.");
    return List.generate(maps.length, (i) {
      final data = AdoptionRoleMaster.fromJson(maps[i]);
      return data;
    });
  }

// Insert CustomerCategory Data into the Database
  Future<void> insertCustomerCategory(CustomerCategory data) async {
    final db = await database;
    await db.insert('CustomerCategory', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//Retrieve CustomerCategory Data from the Database
  Future<List<CustomerCategory>> getCustomerCategoryFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('CustomerCategory');
    print("Getting CustomerCategory from db.");
    return List.generate(maps.length, (i) {
      final data = CustomerCategory.fromJson(maps[i]);
      return data;
    });
  }

// Insert Months Data into the Database
  Future<void> insertMonths(Months data) async {
    final db = await database;
    await db.insert('Months', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//Retrieve Months Data from the Database
  Future<List<Months>> getMonthsFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Months');
    print("Getting Months from db.");
    return List.generate(maps.length, (i) {
      final data = Months.fromJson(maps[i]);
      return data;
    });
  }

// Insert PurchaseMode Data into the Database
  Future<void> insertPurchaseMode(PurchaseMode data) async {
    final db = await database;
    await db.insert('PurchaseMode', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//Retrieve PurchaseMode Data from the Database
  Future<List<PurchaseMode>> getPurchaseModeFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('PurchaseMode');
    print("Getting PurchaseMode from db.");
    return List.generate(maps.length, (i) {
      final data = PurchaseMode.fromJson(maps[i]);
      return data;
    });
  }

// Insert InstituteType Data into the Database
  Future<void> insertInstituteType(InstituteType data) async {
    final db = await database;
    await db.insert('InstituteType', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//Retrieve InstituteType Data from the Database
  Future<List<InstituteType>> getInstituteTypeFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('InstituteType');
    print("Getting InstituteType from db.");
    return List.generate(maps.length, (i) {
      final data = InstituteType.fromJson(maps[i]);
      return data;
    });
  }

// Insert InstituteLevel Data into the Database
  Future<void> insertInstituteLevel(InstituteLevel data) async {
    final db = await database;
    await db.insert('InstituteLevel', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//Retrieve InstituteLevel Data from the Database
  Future<List<InstituteLevel>> getInstituteLevelFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('InstituteLevel');
    print("Getting InstituteLevel from db.");
    return List.generate(maps.length, (i) {
      final data = InstituteLevel.fromJson(maps[i]);
      return data;
    });
  }

// Insert AffiliateType Data into the Database
  Future<void> insertAffiliateType(AffiliateType data) async {
    final db = await database;
    await db.insert('AffiliateType', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

//Retrieve AffiliateType Data from the Database
  Future<List<AffiliateType>> getAffiliateTypeFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('AffiliateType');
    print("Getting AffiliateType from db.");
    return List.generate(maps.length, (i) {
      final data = AffiliateType.fromJson(maps[i]);
      return data;
    });
  }

  Future<void> insertCustomerEntryMasterResponse(
      CustomerEntryMasterResponse response) async {
    final db = await database;

    // Insert BoardMaster List
    for (var boardMaster in response.boardMasterList) {
      await insertBoardMaster(boardMaster);
    }

    // Insert Classes List
    for (var classes in response.classesList) {
      await insertClasses(classes);
    }

    // Insert DataSource List
    for (var dataSource in response.dataSourceList) {
      await insertDataSource(dataSource);
    }

    // Insert ChainSchool List
    for (var chainSchool in response.chainSchoolList) {
      await insertChainSchools(chainSchool);
    }

    // Insert AccountableExecutive List
    for (var accountableExecutive in response.accountableExecutiveList) {
      await insertAccountableExecutive(accountableExecutive);
    }

    // Insert SalutationMaster List
    for (var salutation in response.salutationMasterList) {
      await insertSalutationMaster(salutation);
    }

    // Insert ContactDesignation List
    for (var contactDesignation in response.contactDesignationList) {
      await insertContactDesignation(contactDesignation);
    }
    // Insert Subject List
    for (var subject in response.subjectList) {
      await insertSubject(subject);
    }
    // Insert Department List
    for (var department in response.departmentList) {
      await insertDepartment(department);
    }
    // Insert AdoptionRoleMaster List
    for (var adoptionRole in response.adoptionRoleMasterList) {
      await insertAdoptionRoleMaster(adoptionRole);
    }
    // Insert CustomerCategory List
    for (var customerCategory in response.customerCategoryList) {
      await insertCustomerCategory(customerCategory);
    }
    // Insert Months List
    for (var month in response.monthsList) {
      await insertMonths(month);
    }
    // Insert PurchaseMode List
    for (var purchaseMode in response.purchaseModeList) {
      await insertPurchaseMode(purchaseMode);
    }
    // Insert InstituteType List
    for (var instituteType in response.instituteTypeList) {
      await insertInstituteType(instituteType);
    }
    // Insert InstituteLevel List
    for (var instituteLevel in response.instituteLevelList) {
      await insertInstituteLevel(instituteLevel);
    }
    // Insert AffiliateType List
    for (var affiliateType in response.affiliateTypeList) {
      await insertAffiliateType(affiliateType);
    }
  }

  Future<void> _insertList<T extends JsonSerializable>(
      Database db, String tableName, List<T> list) async {
    for (var item in list) {
      await db.insert(tableName, item.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      print("$tableName $item successfully inserted");
    }
  }

  Future<CustomerEntryMasterResponse?> getCustomerEntryMasterResponse() async {
    final db = await database;

    // Retrieve data from respective tables
    var boardMasterList = await getBoardMasterFromDB();
    var classesList = await getClassesFromDB();
    var chainSchoolList = await getChainSchoolFromDB();
    var dataSourceList = await getDataSourceFromDB();
    var accountableExecutiveList = await getAccountableExecutiveFromDB();
    var salutationMasterList = await getSalutationMasterFromDB();
    var contactDesignationList = await getContactDesignationFromDB();
    var subjectList = await getSubjectFromDB();
    var departmentList = await getDepartmentFromDB();
    var adoptionRoleMasterList = await getAdoptionRoleMasterFromDB();
    var customerCategoryList = await getCustomerCategoryFromDB();
    var monthsList = await getMonthsFromDB();
    var purchaseModeList = await getPurchaseModeFromDB();
    var instituteTypeList = await getInstituteTypeFromDB();
    var instituteLevelList = await getInstituteLevelFromDB();
    var affiliateTypeList = await getAffiliateTypeFromDB();
    // var boardMasterList = await _getList<BoardMaster>(db, 'BoardMaster');
    // var classesList = await _getList<Classes>(db, 'Classes');
    // var chainSchoolList = await _getList<ChainSchool>(db, 'ChainSchool');
    // var dataSourceList = await _getList<DataSource>(db, 'DataSource');
    // var accountableExecutiveList =
    //     await _getList<AccountableExecutive>(db, 'AccountableExecutive');
    // var salutationMasterList =
    //     await _getList<SalutationMaster>(db, 'SalutationMaster');
    // var contactDesignationList =
    //     await _getList<ContactDesignation>(db, 'ContactDesignation');
    // var subjectList = await _getList<Subject>(db, 'Subject');
    // var departmentList = await _getList<Department>(db, 'Department');
    // var adoptionRoleMasterList =
    //     await _getList<AdoptionRoleMaster>(db, 'AdoptionRoleMaster');
    // var customerCategoryList =
    //     await _getList<CustomerCategory>(db, 'CustomerCategory');
    // var monthsList = await _getList<Months>(db, 'Months');
    // var purchaseModeList = await _getList<PurchaseMode>(db, 'PurchaseMode');
    // var instituteTypeList = await _getList<InstituteType>(db, 'InstituteType');
    // var instituteLevelList =
    //     await _getList<InstituteLevel>(db, 'InstituteLevel');
    // var affiliateTypeList = await _getList<AffiliateType>(db, 'AffiliateType');

    // Debugging print statements
    print("Retrieved from DB:");
    // print("BoardMaster: $boardMasterList");
    // print("Classes: $classesList");
    // print("ChainSchool: $chainSchoolList");
    // print("DataSource: $dataSourceList");
    // print("AccountableExecutive: $accountableExecutiveList");
    print("SalutationMaster: $salutationMasterList");
    // print("ContactDesignation: $contactDesignationList");
    // print("Subject: $subjectList");
    // print("Department: $departmentList");
    // print("AdoptionRoleMaster: $adoptionRoleMasterList");
    // print("CustomerCategory: $customerCategoryList");
    // print("Months: $monthsList");
    // print("PurchaseMode: $purchaseModeList");
    // print("InstituteType: $instituteTypeList");
    // print("InstituteLevel: $instituteLevelList");
    // print("AffiliateType: $affiliateTypeList");

    return CustomerEntryMasterResponse(
      status: 'success',
      // Adjust this based on your needs
      boardMasterList: boardMasterList,
      classesList: classesList,
      chainSchoolList: chainSchoolList,
      dataSourceList: dataSourceList,
      accountableExecutiveList: accountableExecutiveList,
      salutationMasterList: salutationMasterList,
      contactDesignationList: contactDesignationList,
      subjectList: subjectList,
      departmentList: departmentList,
      adoptionRoleMasterList: adoptionRoleMasterList,
      customerCategoryList: customerCategoryList,
      monthsList: monthsList,
      purchaseModeList: purchaseModeList,
      instituteTypeList: instituteTypeList,
      instituteLevelList: instituteLevelList,
      affiliateTypeList: affiliateTypeList,
    );
  }

  Future<List<T>> _getList<T>(Database db, String tableName) async {
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return _fromJson<T>(maps[i]);
    });
  }

  T _fromJson<T>(Map<String, dynamic> json) {
    switch (T) {
      case BoardMaster:
        return BoardMaster.fromJson(json) as T;
      case Classes:
        return Classes.fromJson(json) as T;
      case ChainSchool:
        return ChainSchool.fromJson(json) as T;
      case DataSource:
        return DataSource.fromJson(json) as T;
      case AccountableExecutive:
        return AccountableExecutive.fromJson(json) as T;
      case SalutationMaster:
        return SalutationMaster.fromJson(json) as T;
      case ContactDesignation:
        return ContactDesignation.fromJson(json) as T;
      case Subject:
        return Subject.fromJson(json) as T;
      case Department:
        return Department.fromJson(json) as T;
      case AdoptionRoleMaster:
        return AdoptionRoleMaster.fromJson(json) as T;
      case CustomerCategory:
        return CustomerCategory.fromJson(json) as T;
      case Months:
        return Months.fromJson(json) as T;
      case PurchaseMode:
        return PurchaseMode.fromJson(json) as T;
      case InstituteType:
        return InstituteType.fromJson(json) as T;
      case InstituteLevel:
        return InstituteLevel.fromJson(json) as T;
      case AffiliateType:
        return AffiliateType.fromJson(json) as T;
      default:
        throw Exception('Unknown class type');
    }
  }


  //Save Geography Data to the Database
  Future<void> insertGeographyData(Geography data) async {
    final db = await database;
    await db.insert('Geography', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    print('Inserting into DB: ${data.toJson()}');
    print(
        "${data.city}:${data.state}:${data.country} successfully inserted into db.");
  }

  //Retrieve Geography Data from the Database
  Future<List<Geography>> getGeographyDataFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Geography');
    print("Getting Geography data from db.");
    for (var map in maps) {
      print('Raw data from DB: ${map}');
    }
    return List.generate(maps.length, (i) {
      final geography = Geography.fromJson(maps[i]);
      print('Parsed Geography: ${geography.toJson()}');
      return geography;
    });
  }
}
