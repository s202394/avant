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
    List<BoardMaster> boardMasterData =
        listBoardMaster.map((i) => BoardMaster.fromJson(i)).toList();

    var listClasses = json["Classes"] as List;
    List<Classes> classesData =
        listClasses.map((i) => Classes.fromJson(i)).toList();

    var listChainSchool = json["ChainSchool"] as List;
    List<ChainSchool> chainSchoolData =
        listChainSchool.map((i) => ChainSchool.fromJson(i)).toList();

    var listDataSource = json["DataSource"] as List;
    List<DataSource> dataSourceData =
        listDataSource.map((i) => DataSource.fromJson(i)).toList();

    var listAccountableExecutive = json["AccountableExecutive"] as List;
    List<AccountableExecutive> accountableExecutiveData =
        listAccountableExecutive
            .map((i) => AccountableExecutive.fromJson(i))
            .toList();

    var listSalutationMaster = json["SalutationMaster"] as List;
    List<SalutationMaster> salutationMasterData =
        listSalutationMaster.map((i) => SalutationMaster.fromJson(i)).toList();

    var listContactDesignation = json["ContactDesignation"] as List;
    List<ContactDesignation> contactDesignationData = listContactDesignation
        .map((i) => ContactDesignation.fromJson(i))
        .toList();

    var listDepartment = json["Department"] as List;
    List<Department> departmentData =
        listDepartment.map((i) => Department.fromJson(i)).toList();

    var listSubject = json["Subject"] as List;
    List<Subject> subjectData =
        listSubject.map((i) => Subject.fromJson(i)).toList();

    var listAdoptionRoleMaster = json["AdoptionRoleMaster"] as List;
    List<AdoptionRoleMaster> adoptionRoleMasterData = listAdoptionRoleMaster
        .map((i) => AdoptionRoleMaster.fromJson(i))
        .toList();

    var listCustomerCategory = json["CustomerCategory"] as List;
    List<CustomerCategory> customerCategoryData =
        listCustomerCategory.map((i) => CustomerCategory.fromJson(i)).toList();

    var listMonths = json["Months"] as List;
    List<Months> monthsData =
        listMonths.map((i) => Months.fromJson(i)).toList();

    var listInstituteType = json["InstituteType"] as List;
    List<InstituteType> instituteTypeData =
        listInstituteType.map((i) => InstituteType.fromJson(i)).toList();

    var listPurchaseMode = json["PurchaseMode"] as List;
    List<PurchaseMode> purchaseModeData =
        listPurchaseMode.map((i) => PurchaseMode.fromJson(i)).toList();

    var listInstituteLevel = json["InstituteLevel"] as List;
    List<InstituteLevel> instituteLevelData =
        listInstituteLevel.map((i) => InstituteLevel.fromJson(i)).toList();

    var listAffiliateType = json["AffiliateType"] as List;
    List<AffiliateType> affiliateTypeData =
        listAffiliateType.map((i) => AffiliateType.fromJson(i)).toList();

    return CustomerEntryMasterResponse(
      status: json['Status'] ?? '',
      boardMasterList: boardMasterData,
      classesList: classesData,
      chainSchoolList: chainSchoolData,
      dataSourceList: dataSourceData,
      accountableExecutiveList: accountableExecutiveData,
      salutationMasterList: salutationMasterData,
      contactDesignationList: contactDesignationData,
      subjectList: subjectData,
      departmentList: departmentData,
      adoptionRoleMasterList: adoptionRoleMasterData,
      customerCategoryList: customerCategoryData,
      monthsList: monthsData,
      purchaseModeList: purchaseModeData,
      instituteTypeList: instituteTypeData,
      instituteLevelList: instituteLevelData,
      affiliateTypeList: affiliateTypeData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': 'Success',
      'BoardMaster': boardMasterList,
      'Classes': classesList,
      'ChainSchool': chainSchoolList,
      'DataSource': dataSourceList,
      'AccountableExecutive': accountableExecutiveList,
      'SalutationMaster': salutationMasterList,
      'ContactDesignation': contactDesignationList,
      'Department': departmentList,
      'Subject': subjectList,
      'AdoptionRoleMaster': adoptionRoleMasterList,
      'CustomerCategory': customerCategoryList,
      'InstituteType': instituteTypeList,
      'InstituteLevel': instituteLevelList,
      'PurchaseMode': purchaseModeList,
      'AffiliateType': affiliateTypeList,
    };
  }
}

abstract class JsonSerializable {
  Map<String, dynamic> toJson();
}

class BoardMaster implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'BoardId': boardId,
      'BoardName': boardName,
    };
  }
}

class Classes implements JsonSerializable {
  final int classNumId;
  final String className;

  Classes({
    required this.classNumId,
    required this.className,
  });

  factory Classes.fromJson(Map<String, dynamic> json) {
    return Classes(
      classNumId: json['ClassNumId'] ?? 0,
      className: json['ClassName'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'ClassNumId': classNumId,
      'ClassName': className,
    };
  }
}

class ChainSchool implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'ChainSchoolId': chainSchoolId,
      'ChainSchoolName': chainSchoolName,
    };
  }
}

class DataSource implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'DataSourceId': dataSourceId,
      'DataSourceName': dataSourceName,
    };
  }
}

class AccountableExecutive implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'ExecutiveName': executiveName,
    };
  }
}

class SalutationMaster implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'SalutationId': salutationId,
      'SalutationName': salutationName,
    };
  }
}

class ContactDesignation implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'ContactDesignationId': contactDesignationId,
      'ContactDesignationName': contactDesignationName,
    };
  }
}

class Subject implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'SubjectId': subjectId,
      'SubjectName': subjectName,
    };
  }
}

class Department implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'DepartmentId': departmentId,
      'DepartmentName': departmentName,
    };
  }
}

class AdoptionRoleMaster implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'AdoptionRoleId': adoptionRoleId,
      'AdoptionRole': adoptionRole,
    };
  }
}

class CustomerCategory implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'CustomerCategoryId': customerCategoryId,
      'CustomerCategoryName': customerCategoryName,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CustomerCategory &&
        other.customerCategoryId == customerCategoryId &&
        other.customerCategoryName == customerCategoryName;
  }

  @override
  int get hashCode =>
      customerCategoryId.hashCode ^ customerCategoryName.hashCode;

  @override
  String toString() =>
      'CustomerCategory($customerCategoryId, $customerCategoryName)';
}

class Months implements JsonSerializable {
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

  @override
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Name': name,
    };
  }
}

class PurchaseMode implements JsonSerializable {
  final String modeValue;
  final String modeName;

  PurchaseMode({
    required this.modeValue,
    required this.modeName,
  });

  factory PurchaseMode.fromJson(Map<String, dynamic> json) {
    return PurchaseMode(
      modeValue: json['ModeValue'] ?? '',
      modeName: json['ModeName'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'ModeValue': modeValue,
      'ModeName': modeName,
    };
  }
}

class InstituteType implements JsonSerializable {
  final String id;
  final String instituteType;

  InstituteType({
    required this.id,
    required this.instituteType,
  });

  factory InstituteType.fromJson(Map<String, dynamic> json) {
    return InstituteType(
      id: json['ID'] ?? '',
      instituteType: json['InstituteType'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'InstituteType': instituteType,
    };
  }
}

class InstituteLevel implements JsonSerializable {
  final String id;
  final String instituteLevel;

  InstituteLevel({
    required this.id,
    required this.instituteLevel,
  });

  factory InstituteLevel.fromJson(Map<String, dynamic> json) {
    return InstituteLevel(
      id: json['ID'] ?? '',
      instituteLevel: json['InstituteLevel'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'InstituteLevel': instituteLevel,
    };
  }
}

class AffiliateType implements JsonSerializable {
  final String id;
  final String affiliateType;

  AffiliateType({
    required this.id,
    required this.affiliateType,
  });

  factory AffiliateType.fromJson(Map<String, dynamic> json) {
    return AffiliateType(
      id: json['ID'] ?? '',
      affiliateType: json['AffiliateType'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'AffiliateType': affiliateType,
    };
  }
}
