class Plan {
  final String customerName;
  final String customerCode;
  final String visitPurpose;
  final String refCode;
  final String customerType;
  final String address;
  final String city;
  final String state;
  final String emailId;
  final String phone;
  final int customerId;

  Plan({
    required this.customerName,
    required this.customerCode,
    required this.visitPurpose,
    required this.refCode,
    required this.customerType,
    required this.address,
    required this.city,
    required this.state,
    required this.emailId,
    required this.phone,
    required this.customerId,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      customerName: json['CustomerName'] ?? '',
      customerCode: json['CustomerCode'] ?? '',
      visitPurpose: json['VisitPurpose'] ?? '',
      refCode: json['RefCode'] ?? '',
      customerType: json['CustomerType'] ?? '',
      address: json['Address'] ?? '',
      city: json['City'] ?? '',
      state: json['State'] ?? '',
      emailId: json['EmailId'] ?? '',
      phone: json['Phone'] ?? '',
      customerId: json['CustomerId'] ?? 0,
    );
  }
}

class PlanResponse {
  final String status;
  final List<Plan> todayPlan;
  final List<Plan> tomorrowPlan;

  PlanResponse({
    required this.status,
    required this.todayPlan,
    required this.tomorrowPlan,
  });

  factory PlanResponse.fromJson(Map<String, dynamic> json) {
    var todayPlanList = json["TodayPlan"] as List;
    var tomorrowPlanList = json["TommorowPlan"] as List;
    List<Plan> todayPlan = todayPlanList.map((i) => Plan.fromJson(i)).toList();
    List<Plan> tomorrowPlan = tomorrowPlanList.map((i) => Plan.fromJson(i)).toList();

    return PlanResponse(
      status: json['Status'] ?? '',
      todayPlan: todayPlan,
      tomorrowPlan: tomorrowPlan,
    );
  }
}