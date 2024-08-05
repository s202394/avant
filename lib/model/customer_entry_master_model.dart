class CustomerEntryMasterResponse {
  final String status;
  final List<BoardMaster> boardMasterList;
  final List<Classes> classesList;
  final List<DataSource> dataSourceList;
  final List<ChainSchool> chainSchoolList;
  final List<AccountableExecutive> accountableExecutiveList;
  final List<SalutationMaster> salutationMasterList;
  final List<ContactDesignation> contactDesignationList;
  final List<Subject> subjectList;
  final List<Department> departmentList;
  final List<AdoptionRoleMaster> adoptionRoleMasterList;
  final List<CustomerCategory> customerCategoryList;
  final List<Months> monthsList;
  final List<PurchaseMode> purchaseModeList;
  final List<InstituteType> instituteTypeList;
  final List<InstituteLevel> instituteLevelList;
  final List<AffiliateType> affiliateTypeList;

  CustomerEntryMasterResponse({
    required this.status,
    required this.boardMasterList,
    required this.classesList,
    required this.chainSchoolList,
    required this.dataSourceList,
    required this.accountableExecutiveList,
    required this.salutationMasterList,
    required this.contactDesignationList,
    required this.subjectList,
    required this.departmentList,
    required this.adoptionRoleMasterList,
    required this.customerCategoryList,
    required this.monthsList,
    required this.purchaseModeList,
    required this.instituteTypeList,
    required this.instituteLevelList,
    required this.affiliateTypeList,
  });

  factory CustomerEntryMasterResponse.fromJson(Map<String, dynamic> json) {
    var listBoardMaster = json["BoardMaster"] as List;
    List<BoardMaster> boardMaster =
        listBoardMaster.map((i) => BoardMaster.fromJson(i)).toList();

    var listClasses = json["Classes"] as List;
    List<Classes> classes =
        listClasses.map((i) => Classes.fromJson(i)).toList();

    var listChainSchool = json["ChainSchool"] as List;
    List<ChainSchool> chainSchool =
        listChainSchool.map((i) => ChainSchool.fromJson(i)).toList();

    var listDataSource = json["DataSource"] as List;
    List<DataSource> dataSource =
        listDataSource.map((i) => DataSource.fromJson(i)).toList();

    var listAccountableExecutive = json["AccountableExecutive"] as List;
    List<AccountableExecutive> accountableExecutive = listAccountableExecutive
        .map((i) => AccountableExecutive.fromJson(i))
        .toList();

    var listSalutationMaster = json["SalutationMaster"] as List;
    List<SalutationMaster> salutationMaster =
        listSalutationMaster.map((i) => SalutationMaster.fromJson(i)).toList();

    var listContactDesignation = json["ContactDesignation"] as List;
    List<ContactDesignation> contactDesignation = listContactDesignation
        .map((i) => ContactDesignation.fromJson(i))
        .toList();

    var listDepartment = json["Department"] as List;
    List<Department> department =
        listDepartment.map((i) => Department.fromJson(i)).toList();

    var listSubject = json["Subject"] as List;
    List<Subject> subject =
        listSubject.map((i) => Subject.fromJson(i)).toList();

    var listAdoptionRoleMaster = json["AdoptionRoleMaster"] as List;
    List<AdoptionRoleMaster> adoptionRoleMaster = listAdoptionRoleMaster
        .map((i) => AdoptionRoleMaster.fromJson(i))
        .toList();

    var listCustomerCategory = json["CustomerCategory"] as List;
    List<CustomerCategory> customerCategory =
        listCustomerCategory.map((i) => CustomerCategory.fromJson(i)).toList();

    var listMonths = json["Months"] as List;
    List<Months> months = listMonths.map((i) => Months.fromJson(i)).toList();

    var listInstituteType = json["InstituteType"] as List;
    List<InstituteType> instituteType =
        listInstituteType.map((i) => InstituteType.fromJson(i)).toList();

    var listPurchaseMode = json["PurchaseMode"] as List;
    List<PurchaseMode> purchaseMode =
        listPurchaseMode.map((i) => PurchaseMode.fromJson(i)).toList();

    var listInstituteLevel = json["InstituteLevel"] as List;
    List<InstituteLevel> instituteLevel =
        listInstituteLevel.map((i) => InstituteLevel.fromJson(i)).toList();

    var listAffiliateType = json["AffiliateType"] as List;
    List<AffiliateType> AffiliateType =
        listAffiliateType.map((i) => AffiliateType.fromJson(i)).toList();

    return CustomerEntryMasterResponse(
      status: json['Status'] ?? '',
      boardMasterList: boardMaster,
      classesList: classes,
      chainSchoolList: chainSchool,
      dataSourceList: dataSource,
      accountableExecutiveList: adoptionRoleMaster,
      salutationMasterList: salutationMaster,
      contactDesignationList: contactDesignation,
      subjectList: subject,
      departmentList: department,
      adoptionRoleMasterList: adoptionRoleMaster,
      customerCategoryList: customerCategory,
      monthsList: months,
      purchaseModeList: purchaseMode,
      instituteTypeList: instituteType,
      instituteLevelList: instituteLevel,
      affiliateTypeList: affiliateType,
    );
  }
}

class BoardMaster {
  final int boardId;
  final String boardName;

  BoardMaster({
    required this.boardId,
    required this.boardName,
  });

  factory BoardMaster.fromJson(Map<String, dynamic> json) {
    return BoardMaster(
      boardId: json['BoardId'] ?? 0,
      boardName: json['BoardName'] ?? '',
    );
  }
}

class Classes {
  final int classNumId;
  final String className;

  Classes({
    required this.classNumId,
    required this.className,
  });

  factory Classes.fromJson(Map<String, dynamic> json) {
    return Classes(
      classNumId: json['ClassNumId'] ?? 0,
      className: json['ClassName'] ?? 0,
    );
  }
}

class ChainSchool {
  final int chainSchoolId;
  final String chainSchoolName;

  ChainSchool({
    required this.chainSchoolId,
    required this.chainSchoolName,
  });

  factory ChainSchool.fromJson(Map<String, dynamic> json) {
    return ChainSchool(
      chainSchoolId: json['ChainSchoolId'] ?? 0,
      chainSchoolName: json['ChainSchoolName'] ?? '',
    );
  }
}

class DataSource {
  final int dataSourceId;
  final String dataSourceName;

  DataSource({
    required this.dataSourceId,
    required this.dataSourceName,
  });

  factory DataSource.fromJson(Map<String, dynamic> json) {
    return DataSource(
      dataSourceId: json['DataSourceId'] ?? 0,
      dataSourceName: json['DataSourceName'] ?? '',
    );
  }
}

class AccountableExecutive {
  final int sNo;
  final String executiveName;

  AccountableExecutive({
    required this.sNo,
    required this.executiveName,
  });

  factory AccountableExecutive.fromJson(Map<String, dynamic> json) {
    return AccountableExecutive(
      sNo: json['SNo'] ?? 0,
      executiveName: json['ExecutiveName'] ?? '',
    );
  }
}

class SalutationMaster {
  final int salutationId;
  final String salutationName;

  SalutationMaster({
    required this.salutationId,
    required this.salutationName,
  });

  factory SalutationMaster.fromJson(Map<String, dynamic> json) {
    return SalutationMaster(
      salutationId: json['SalutationId'] ?? 0,
      salutationName: json['SalutationName'] ?? '',
    );
  }
}

class ContactDesignation {
  final int contactDesignationId;
  final String contactDesignationName;

  ContactDesignation({
    required this.contactDesignationId,
    required this.contactDesignationName,
  });

  factory ContactDesignation.fromJson(Map<String, dynamic> json) {
    return ContactDesignation(
      contactDesignationId: json['ContactDesignationId'] ?? 0,
      contactDesignationName: json['ContactDesignationName'] ?? '',
    );
  }
}

class Subject {
  final int subjectId;
  final String subjectName;

  Subject({
    required this.subjectId,
    required this.subjectName,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subjectId: json['SubjectId'] ?? 0,
      subjectName: json['SubjectName'] ?? '',
    );
  }
}

class Department {
  final int departmentId;
  final String departmentName;

  Department({
    required this.departmentId,
    required this.departmentName,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: json['DepartmentId'] ?? 0,
      departmentName: json['DepartmentName'] ?? '',
    );
  }
}

class AdoptionRoleMaster {
  final int adoptionRoleId;
  final String adoptionRole;

  AdoptionRoleMaster({
    required this.adoptionRoleId,
    required this.adoptionRole,
  });

  factory AdoptionRoleMaster.fromJson(Map<String, dynamic> json) {
    return AdoptionRoleMaster(
      adoptionRoleId: json['AdoptionRoleId'] ?? 0,
      adoptionRole: json['AdoptionRole'] ?? '',
    );
  }
}

class CustomerCategory {
  final int customerCategoryId;
  final String customerCategoryName;

  CustomerCategory({
    required this.customerCategoryId,
    required this.customerCategoryName,
  });

  factory CustomerCategory.fromJson(Map<String, dynamic> json) {
    return CustomerCategory(
      customerCategoryId: json['CustomerCategoryId'] ?? 0,
      customerCategoryName: json['CustomerCategoryName'] ?? '',
    );
  }
}

class Months {
  final int id;
  final String name;

  Months({
    required this.id,
    required this.name,
  });

  factory Months.fromJson(Map<String, dynamic> json) {
    return Months(
      id: json['ID'] ?? 0,
      name: json['Name'] ?? '',
    );
  }
}

class PurchaseMode {
  final int modeValue;
  final String modeName;

  PurchaseMode({
    required this.modeValue,
    required this.modeName,
  });

  factory PurchaseMode.fromJson(Map<String, dynamic> json) {
    return PurchaseMode(
      modeValue: json['ModeValue'] ?? 0,
      modeName: json['ModeName'] ?? '',
    );
  }
}

class InstituteType {
  final int id;
  final String instituteType;

  InstituteType({
    required this.id,
    required this.instituteType,
  });

  factory InstituteType.fromJson(Map<String, dynamic> json) {
    return InstituteType(
      id: json['ID'] ?? 0,
      instituteType: json['InstituteType'] ?? '',
    );
  }
}

class InstituteLevel {
  final int id;
  final String instituteLevel;

  InstituteLevel({
    required this.id,
    required this.instituteLevel,
  });

  factory InstituteLevel.fromJson(Map<String, dynamic> json) {
    return InstituteLevel(
      id: json['ID'] ?? 0,
      instituteLevel: json['InstituteLevel'] ?? '',
    );
  }
}

class AffiliateType {
  final int id;
  final String affiliateType;

  AffiliateType({
    required this.id,
    required this.affiliateType,
  });

  factory AffiliateType.fromJson(Map<String, dynamic> json) {
    return AffiliateType(
      id: json['ID'] ?? 0,
      affiliateType: json['AffiliateType'] ?? '',
    );
  }
}
