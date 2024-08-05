class MenuData {
  final String menuName;
  final String childMenuName;
  final String linkURL;

  MenuData({
    required this.menuName,
    required this.childMenuName,
    required this.linkURL,
  });

  factory MenuData.fromJson(Map<String, dynamic> json) {
    return MenuData(
      menuName: json['MenuName'] ?? '',
      childMenuName: json['ChildMenuName'] ?? '',
      linkURL: json['LinkURL'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MenuName': menuName,
      'ChildMenuName': childMenuName,
      'LinkURL': linkURL,
    };
  }
}