class CustomerListResponse {
  final String status;
  final List<CustomerList> customerList;

  CustomerListResponse({
    required this.status,
    required this.customerList,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    var listApproval = json["CustomerList"] as List;
    List<CustomerList> resultList =
        listApproval.map((i) => CustomerList.fromJson(i)).toList();

    return CustomerListResponse(
      status: json['Status'] ?? '',
      customerList: resultList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'CustomerList': customerList.map((e) => e.toJson()).toList(),
    };
  }
}

class CustomerList {
  final int sNo;
  final String schoolCode;
  final String schoolName;
  final String refCode;
  final String address;
  final String city;
  final String state;
  final String validationStatus;
  final int existence;
  final String action;

  CustomerList({
    required this.sNo,
    required this.schoolCode,
    required this.schoolName,
    required this.refCode,
    required this.address,
    required this.city,
    required this.state,
    required this.validationStatus,
    required this.existence,
    required this.action,
  });

  factory CustomerList.fromJson(Map<String, dynamic> json) {
    return CustomerList(
      sNo: json['SNo'] ?? 0,
      schoolCode: json['SchoolCode'] ?? '',
      schoolName: json['SchoolName'] ?? '',
      refCode: json['RefCode'] ?? '',
      address: json['Address'] ?? '',
      city: json['City'] ?? '',
      state: json['State'] ?? '',
      validationStatus: json['ValidationStatus'] ?? '',
      existence: json['Existence'] ?? 0,
      action: json['Action'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'SchoolCode': schoolCode,
      'SchoolName': schoolName,
      'RefCode': refCode,
      'Address': address,
      'City': city,
      'State': state,
      'ValidationStatus': validationStatus,
      'Existence': existence,
      'Action': action,
    };
  }
}

class CustomerListTradeResponse {
  final String status;
  final List<CustomerListTrade> customerList;

  CustomerListTradeResponse({
    required this.status,
    required this.customerList,
  });

  factory CustomerListTradeResponse.fromJson(Map<String, dynamic> json) {
    var listApproval = json["CustomerList"] as List;
    List<CustomerListTrade> resultList =
        listApproval.map((i) => CustomerListTrade.fromJson(i)).toList();

    return CustomerListTradeResponse(
      status: json['Status'] ?? '',
      customerList: resultList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'CustomerList': customerList.map((e) => e.toJson()).toList(),
    };
  }
}

class CustomerListTrade {
  final int sNo;
  final String customerCode;
  final String customerName;
  final String refCode;
  final String address;
  final String city;
  final String state;
  final String validationStatus;
  final int existence;
  final String action;

  CustomerListTrade({
    required this.sNo,
    required this.customerCode,
    required this.customerName,
    required this.refCode,
    required this.address,
    required this.city,
    required this.state,
    required this.validationStatus,
    required this.existence,
    required this.action,
  });

  factory CustomerListTrade.fromJson(Map<String, dynamic> json) {
    return CustomerListTrade(
      sNo: json['SNo'] ?? 0,
      customerCode: json['CustomerCode'] ?? '',
      customerName: json['CustomerName'] ?? '',
      refCode: json['RefCode'] ?? '',
      address: json['Address'] ?? '',
      city: json['City'] ?? '',
      state: json['State'] ?? '',
      validationStatus: json['ValidationStatus'] ?? '',
      existence: json['Existence'] ?? 0,
      action: json['Action'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'CustomerCode': customerCode,
      'CustomerName': customerName,
      'RefCode': refCode,
      'Address': address,
      'City': city,
      'State': state,
      'ValidationStatus': validationStatus,
      'Existence': existence,
      'Action': action,
    };
  }
}

class CommonCustomerList {
  final int sNo;
  final String code; // Common for `schoolCode` or `customerCode`
  final String name; // Common for `schoolName` or `customerName`
  final String refCode;
  final String address;
  final String city;
  final String state;
  final String validationStatus;
  final int existence;
  final String action;

  CommonCustomerList({
    required this.sNo,
    required this.code,
    required this.name,
    required this.refCode,
    required this.address,
    required this.city,
    required this.state,
    required this.validationStatus,
    required this.existence,
    required this.action,
  });

  factory CommonCustomerList.fromSchool(CustomerList school) {
    return CommonCustomerList(
      sNo: school.sNo,
      code: school.schoolCode,
      name: school.schoolName,
      refCode: school.refCode,
      address: school.address,
      city: school.city,
      state: school.state,
      validationStatus: school.validationStatus,
      existence: school.existence,
      action: school.action,
    );
  }

  factory CommonCustomerList.fromTrade(CustomerListTrade trade) {
    return CommonCustomerList(
      sNo: trade.sNo,
      code: trade.customerCode,
      name: trade.customerName,
      refCode: trade.refCode,
      address: trade.address,
      city: trade.city,
      state: trade.state,
      validationStatus: trade.validationStatus,
      existence: trade.existence,
      action: trade.action,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'Code': code,
      'Name': name,
      'RefCode': refCode,
      'Address': address,
      'City': city,
      'State': state,
      'ValidationStatus': validationStatus,
      'Existence': existence,
      'Action': action,
    };
  }
}

class CustomerContactListResponse {
  final String status;
  final List<ContactList> contactList;

  CustomerContactListResponse({
    required this.status,
    required this.contactList,
  });

  factory CustomerContactListResponse.fromJson(Map<String, dynamic> json) {
    var listContact = json["ContactList"] as List;
    List<ContactList> resultList =
        listContact.map((i) => ContactList.fromJson(i)).toList();

    return CustomerContactListResponse(
      status: json['Status'] ?? '',
      contactList: resultList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'ContactList': contactList.map((e) => e.toJson()).toList(),
    };
  }
}

class ContactList {
  final int sNo;
  final String contactName;
  final String designation;
  final String department;
  final String hod;
  final String mobile;
  final String email;
  final String primaryContact;
  final String validationStatus;
  final String edit;
  final String delete;

  ContactList({
    required this.sNo,
    required this.contactName,
    required this.designation,
    required this.department,
    required this.hod,
    required this.mobile,
    required this.email,
    required this.primaryContact,
    required this.validationStatus,
    required this.edit,
    required this.delete,
  });

  factory ContactList.fromJson(Map<String, dynamic> json) {
    return ContactList(
      sNo: json['SNo'] ?? 0,
      contactName: json['ContactName'] ?? '',
      designation: json['Designation'] ?? '',
      department: json['Department'] ?? '',
      hod: json['HOD'] ?? '',
      mobile: json['Mobile'] ?? '',
      email: json['Email'] ?? '',
      primaryContact: json['PrimaryContact'] ?? '',
      validationStatus: json['ValidationStatus'] ?? '',
      edit: json['Edit'] ?? '',
      delete: json['Delete'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'ContactName': contactName,
      'Designation': designation,
      'Department': department,
      'HOD': hod,
      'Mobile': mobile,
      'Email': email,
      'PrimaryContact': primaryContact,
      'ValidationStatus': validationStatus,
      'Action': edit,
      'Delete': delete,
    };
  }
}
