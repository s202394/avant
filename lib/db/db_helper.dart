import 'package:avant/model/customer_entry_master_model.dart';
import 'package:avant/model/geography_model.dart';
import 'package:avant/model/login_model.dart';
import 'package:avant/model/menu_model.dart';
import 'package:avant/model/setup_values.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
        if (kDebugMode) {
          print("applicationSetup table successfully created.");
        }
        await database.execute(
          "CREATE TABLE menuData(MenuName TEXT, ChildMenuName TEXT, LinkURL TEXT)",
        );
        if (kDebugMode) {
          print("menuData table successfully created.");
        }

        //Start Create tables for each list in the CustomerEntryMasterResponse
        await database.execute(
          "CREATE TABLE BoardMaster(BoardId INTEGER PRIMARY KEY, BoardName TEXT)",
        );
        if (kDebugMode) {
          print("BoardMaster table successfully created.");
        }

        await database.execute(
          "CREATE TABLE Classes(ClassNumId INTEGER PRIMARY KEY, ClassName TEXT)",
        );
        if (kDebugMode) {
          print("Classes table successfully created.");
        }

        await database.execute(
          "CREATE TABLE DataSource(DataSourceId INTEGER PRIMARY KEY, DataSourceName TEXT)",
        );
        if (kDebugMode) {
          print("DataSource table successfully created.");
        }

        await database.execute(
          "CREATE TABLE ChainSchool(ChainSchoolId INTEGER PRIMARY KEY, ChainSchoolName TEXT)",
        );
        if (kDebugMode) {
          print("ChainSchool table successfully created.");
        }

        await database.execute(
          "CREATE TABLE AccountableExecutive(SNo INTEGER PRIMARY KEY, ExecutiveName TEXT)",
        );
        if (kDebugMode) {
          print("AccountableExecutive table successfully created.");
        }

        await database.execute(
          "CREATE TABLE SalutationMaster(SalutationId INTEGER PRIMARY KEY, SalutationName TEXT)",
        );
        if (kDebugMode) {
          print("SalutationMaster table successfully created.");
        }

        await database.execute(
          "CREATE TABLE ContactDesignation(ContactDesignationId INTEGER PRIMARY KEY, ContactDesignationName TEXT)",
        );
        if (kDebugMode) {
          print("ContactDesignation table successfully created.");
        }

        await database.execute(
          "CREATE TABLE Subject(SubjectId INTEGER PRIMARY KEY, SubjectName TEXT)",
        );
        if (kDebugMode) {
          print("Subject table successfully created.");
        }

        await database.execute(
          "CREATE TABLE Department(DepartmentId INTEGER PRIMARY KEY, DepartmentName TEXT)",
        );
        if (kDebugMode) {
          print("Department table successfully created.");
        }

        await database.execute(
          "CREATE TABLE AdoptionRoleMaster(AdoptionRoleId INTEGER PRIMARY KEY, AdoptionRole TEXT)",
        );
        if (kDebugMode) {
          print("AdoptionRoleMaster table successfully created.");
        }

        await database.execute(
          "CREATE TABLE CustomerCategory(CustomerCategoryId INTEGER PRIMARY KEY, CustomerCategoryName TEXT)",
        );
        if (kDebugMode) {
          print("CustomerCategory table successfully created.");
        }

        await database.execute(
          "CREATE TABLE Months(ID INTEGER PRIMARY KEY, Name TEXT)",
        );
        if (kDebugMode) {
          print("Months table successfully created.");
        }

        await database.execute(
          "CREATE TABLE PurchaseMode(ModeValue TEXT PRIMARY KEY, ModeName TEXT)",
        );
        if (kDebugMode) {
          print("PurchaseMode table successfully created.");
        }

        await database.execute(
          "CREATE TABLE InstituteType(ID TEXT PRIMARY KEY, InstituteType TEXT)",
        );
        if (kDebugMode) {
          print("InstituteType table successfully created.");
        }

        await database.execute(
          "CREATE TABLE InstituteLevel(ID TEXT PRIMARY KEY, InstituteLevel TEXT)",
        );
        if (kDebugMode) {
          print("InstituteLevel table successfully created.");
        }

        await database.execute(
          "CREATE TABLE AffiliateType(ID TEXT PRIMARY KEY, AffiliateType TEXT)",
        );
        if (kDebugMode) {
          print("AffiliateType table successfully created.");
        }
        // End Create tables for each list in the CustomerEntryMasterResponse

        //Create table for Geography
        await database.execute(
          "CREATE TABLE Geography(CountryId Int, Country TEXT, StateId Int, State TEXT, CityId Int, City TEXT)",
        );
        if (kDebugMode) {
          print("Geography table successfully created.");
        }

        //Create table for SetupValues
        await database.execute(
          "CREATE TABLE setupValues (Id INTEGER PRIMARY KEY, KeyName TEXT NOT NULL, KeyValue TEXT NOT NULL, KeyStatus INTEGER NOT NULL, KeyDescription TEXT)",
        );
        if (kDebugMode) {
          print("SetupValues table successfully created.");
        }

        //Create table for Book Cart
        await database.execute(
          "CREATE TABLE Cart (BookId INTEGER PRIMARY KEY, SeriesId INTEGER, Title TEXT, ISBN TEXT, Author TEXT, Price TEXT, ListPrice REAL, BookNum TEXT, Image TEXT, BookType TEXT, ImageUrl TEXT, PhysicalStock INTEGER, RequestedQty INTEGER DEFAULT 0, ShipTo TEXT, ShippingAddress TEXT, SamplingType TEXT, SampleTo INTEGER DEFAULT 0, SampleGiven TEXT, MRP INTEGER)",
        );
        if (kDebugMode) {
          print("Cart table successfully created.");
        }

        //Create table for FollowUpActionCart
        await database.execute("CREATE TABLE FollowUpActionCart ("
            "Id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "FollowUpAction TEXT, "
            "FollowUpDate INTEGER, "
            "DepartmentId INTEGER, "
            "Department TEXT, "
            "FollowUpExecutiveId INTEGER, "
            "FollowUpExecutive TEXT)");
        if (kDebugMode) {
          print("FollowUpActionCart table successfully created.");
        }
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
    if (kDebugMode) {
      print("${data.key}:${data.keyValue} successfully inserted into db.");
    }
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

  Future<String?> getCustomerTypesFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'applicationSetup',
      where: 'key = ?',
      whereArgs: ['CustomerTypes'],
    );

    if (maps.isNotEmpty) {
      // If the record exists, return the keyValue
      return maps.first['KeyValue'] as String;
    } else {
      // Return null if no record is found
      return null;
    }
  }

  Future<List<String>> getCustomerTypesListFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'applicationSetup',
      where: 'key = ?',
      whereArgs: ['CustomerTypes'],
    );
    if (maps.isNotEmpty) {
      // If the record exists, get the KeyValue and split it by comma
      String customerTypes = maps.first['keyValue'];
      List<String> customerTypesList = customerTypes.split(',');

      // Add 'School' at the first position
      customerTypesList.insert(0, 'School');

      return customerTypesList; // Return the updated list
    } else {
      // If no record is found, return a list with only 'School'
      return ['School'];
    }
  }

  //Save Menu Data to the Database
  Future<void> insertMenuData(MenuData data) async {
    final db = await database;
    await db.insert('menuData', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    if (kDebugMode) {
      print('Inserting into DB: ${data.toJson()}');
    }
    if (kDebugMode) {
      print(
          "${data.menuName}:${data.childMenuName} successfully inserted into db.");
    }
  }

  //Retrieve Menu Data from the Database
  Future<List<MenuData>> getMenuDataFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('menuData');

    if (kDebugMode) {
      print("Getting menu data from db.");
    }
    if (maps.isEmpty) {
      if (kDebugMode) {
        print('No data found in DB.');
      }
      return []; // Return an empty list instead of null
    }

    return List.generate(maps.length, (i) {
      final menuData = MenuData.fromJson(maps[i]);
      /*if (kDebugMode) {
        print('Parsed MenuData: ${menuData.toJson()}');
      }*/
      return menuData;
    });
  }

  Future<void> checkMenuData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('menuData');
    if (kDebugMode) {
      print("Menu Data from DB:");
    }
    for (var map in maps) {
      if (kDebugMode) {
        print(map);
      }
    }
  }

  Future<void> clearMenuDataDatabase() async {
    final db = await database;
    await db.delete('menuData');
    if (kDebugMode) {
      print("Menu Data successfully deleted.");
    }
  }

// Insert BoardMaster Data into the Database
  Future<void> insertBoardMaster(BoardMaster data) async {
    final db = await database;
    await db.insert('BoardMaster', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    if (kDebugMode) {
      print(
          "BoardMaster ${data.boardId}:${data.boardName} successfully inserted into db.");
    }
  }

  //Retrieve BoardMaster Data from the Database
  Future<List<BoardMaster>> getBoardMasterFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('BoardMaster');
    if (kDebugMode) {
      print("Getting BoardMaster from db.");
    }
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
    if (kDebugMode) {
      print("Getting Classes from db.");
    }
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
    if (kDebugMode) {
      print("Getting DataSource from db.");
    }
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
    if (kDebugMode) {
      print("Getting ChainSchool from db.");
    }
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
    if (kDebugMode) {
      print("Getting AccountableExecutive from db.");
    }
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
    if (kDebugMode) {
      print("Getting SalutationMaster from db.");
    }
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
    if (kDebugMode) {
      print("Getting ContactDesignation from db.");
    }
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
    if (kDebugMode) {
      print("Getting Subject from db.");
    }
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
    if (kDebugMode) {
      print("Getting Department from db.");
    }
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
    if (kDebugMode) {
      print("Getting AdoptionRoleMaster from db.");
    }
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
    if (kDebugMode) {
      print("Getting CustomerCategory from db.");
    }
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
    if (kDebugMode) {
      print("Getting Months from db.");
    }
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
    if (kDebugMode) {
      print("Getting PurchaseMode from db.");
    }
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
    if (kDebugMode) {
      print("Getting InstituteType from db.");
    }
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
    if (kDebugMode) {
      print("Getting InstituteLevel from db.");
    }
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
    if (kDebugMode) {
      print("Getting AffiliateType from db.");
    }
    return List.generate(maps.length, (i) {
      final data = AffiliateType.fromJson(maps[i]);
      return data;
    });
  }

  Future<void> insertCustomerEntryMasterResponse(
      CustomerEntryMasterResponse response) async {
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

  Future<CustomerEntryMasterResponse?> getCustomerEntryMasterResponse() async {
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

    return CustomerEntryMasterResponse(
      status: 'success',
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

  //Save Geography Data to the Database
  Future<void> insertGeographyData(Geography data) async {
    final db = await database;
    await db.insert('Geography', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    if (kDebugMode) {
      print('Inserting into DB: ${data.toJson()}');
    }
  }

  //Retrieve Geography Data from the Database
  Future<List<Geography>> getGeographyDataFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('Geography');
    if (kDebugMode) {
      print("Getting Geography data from db.");
    }
    return List.generate(maps.length, (i) {
      return Geography.fromJson(maps[i]);
    });
  }

  //Save SetupValues Data to the Database
  Future<void> insertSetupValueData(SetupValues data) async {
    final db = await database;
    await db.insert('setupValues', data.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    if (kDebugMode) {
      print("${data.keyName}:${data.keyValue} successfully inserted into db.");
    }
  }

  //Retrieve SetupValues Data from the Database
  Future<List<SetupValues>> getSetupValuesDataFromDB() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('setupValues');
    if (kDebugMode) {
      print("Getting SetupValues data from db.");
    }
    return List.generate(maps.length, (i) {
      return SetupValues.fromJson(maps[i]);
    });
  }

  //Start Cart
  //Insert
  Future<void> insertCartItem(Map<String, dynamic> cartItem) async {
    final db = await database;
    await db.insert('Cart', cartItem,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //Delete
  Future<void> deleteCartItem(int bookId) async {
    final db = await database;
    await db.delete('Cart', where: 'BookId = ?', whereArgs: [bookId]);
  }

  //Update
  Future<void> updateCartItem(
      int bookId, Map<String, dynamic> newValues) async {
    final db = await database;
    await db
        .update('Cart', newValues, where: 'BookId = ?', whereArgs: [bookId]);
  }

  //Get Series Items
  Future<List<Map<String, dynamic>>> getCartItemsWithTitle() async {
    final db = await database;
    return await db.query(
      'Cart',
      where: 'SeriesId = ?',
      whereArgs: [0],
    );
  }

  //Get Title Items
  Future<List<Map<String, dynamic>>> getCartItemsWithSeries() async {
    final db = await database;
    return await db.query('Cart', where: 'SeriesId != ?', whereArgs: [0]);
  }

  //Get Title Items
  Future<List<Map<String, dynamic>>> getCartItemsWithSampleGiven(
      String sampleGiven) async {
    final db = await database;
    return await db
        .query('Cart', where: 'SampleGiven = ?', whereArgs: [sampleGiven]);
  }

  //Retrieve all records from Cart
  Future<List<Map<String, dynamic>>> getAllCarts() async {
    final db = await database;
    return await db.query('Cart');
  }

  //Delete all records from Cart
  Future<void> deleteAllCartItems() async {
    final db = await database;
    await db.delete('Cart');
  }

  Future<int> getItemCount() async {
    final db = await database;

    // Query to count the number of items in the Cart
    final result = await db.rawQuery('SELECT COUNT(*) AS itemCount FROM Cart');

    // Extracting the item count
    int itemCount = result[0]['itemCount'] as int;

    return itemCount;
  }

  Future<int> getTotalRequestedQty() async {
    int totalRequestedQty = await database.then((db) async {
      var result = await db
          .rawQuery('SELECT SUM(RequestedQty) AS TotalRequestedQty FROM Cart');
      if (result.isNotEmpty && result.first['TotalRequestedQty'] != null) {
        return result.first['TotalRequestedQty'] as int;
      }
      return 0;
    });
    return totalRequestedQty;
  }

  Future<double> getTotalPrice() async {
    final db = await database;

    // Query to calculate total price
    final result = await db.rawQuery(
        'SELECT SUM(ListPrice * RequestedQty) AS totalPrice FROM Cart');

    // Extracting the total price
    double totalPrice = result[0]['totalPrice'] != null
        ? (result[0]['totalPrice'] as double)
        : 0.0;

    return totalPrice;
  }

  //End Cart

  //Start FollowUpActionCart
  //Insert in FollowUpActionCart
  Future<void> insertFollowUpActionCart(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('FollowUpActionCart', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //Retrieve all records from FollowUpActionCart
  Future<List<Map<String, dynamic>>> getAllFollowUpActionCarts() async {
    final db = await database;
    return await db.query('FollowUpActionCart');
  }

  //Retrieve a specific record by Id from FollowUpActionCart
  Future<Map<String, dynamic>?> getFollowUpActionCartById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result =
        await db.query('FollowUpActionCart', where: 'Id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  //Update Operation from FollowUpActionCart
  Future<void> updateFollowUpActionCart(
      int id, Map<String, dynamic> data) async {
    final db = await database;
    await db
        .update('FollowUpActionCart', data, where: 'Id = ?', whereArgs: [id]);
  }

  //Delete a specific record by Id from FollowUpActionCart
  Future<void> deleteFollowUpActionCart(int id) async {
    final db = await database;
    await db.delete('FollowUpActionCart', where: 'Id = ?', whereArgs: [id]);
  }

  //Delete all records from FollowUpActionCart
  Future<void> deleteAllFollowUpActionCarts() async {
    final db = await database;
    await db.delete('FollowUpActionCart');
  }
//END FollowUpActionCart

  Future<String?> getVisitFeedbackMandatory() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'setupValues', // Your table name
      columns: ['KeyValue'], // Only fetch the keyValue column
      where: 'KeyName = ?',
      whereArgs: ['VisitFeedbackMandatory'],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['KeyValue'] as String?;
    }
    return null; // Return null if the key doesn't exist in the DB
  }
  Future<int?> getVisitFeedbackMinChar() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'setupValues', // Your table name
      columns: ['KeyValue'], // Only fetch the keyValue column
      where: 'KeyName = ?',
      whereArgs: ['VisitFeedbackMinChar'],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return int.tryParse(result.first['KeyValue'] as String? ?? '0');
    }
    return null; // Return null if the key doesn't exist or cannot be parsed to an int
  }
}
