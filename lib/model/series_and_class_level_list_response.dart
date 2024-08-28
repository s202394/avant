class SeriesAndClassLevelListResponse {
  final String? status;
  final List<ClassLevelList>? classLevelList;
  final List<SeriesList>? seriesList;

  SeriesAndClassLevelListResponse({
    this.status,
    this.classLevelList,
    this.seriesList,
  });

  factory SeriesAndClassLevelListResponse.fromJson(Map<String, dynamic> json) {
    var classLevelListData = json["ClassLavelList"] as List?;
    List<ClassLevelList>? classLevelList;
    if (classLevelListData != null && classLevelListData.isNotEmpty) {
      classLevelList =
          classLevelListData.map((i) => ClassLevelList.fromJson(i)).toList();
    }
    var seriesListData = json["SeriesList"] as List?;
    List<SeriesList>? seriesList;
    if (seriesListData != null && seriesListData.isNotEmpty) {
      seriesList =
          seriesListData.map((i) => SeriesList.fromJson(i)).toList();
    }

    return SeriesAndClassLevelListResponse(
      status: json['Status'] as String?,
      classLevelList: classLevelList,
      seriesList: seriesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'ClassLavelList': classLevelList?.map((e) => e.toJson()).toList(),
      'SeriesList': seriesList?.map((e) => e.toJson()).toList(),
    };
  }
}

class ClassLevelList {
  final int classLevelId;
  final String classLevelName;

  ClassLevelList({
    required this.classLevelId,
    required this.classLevelName,
  });

  factory ClassLevelList.fromJson(Map<String, dynamic> json) {
    return ClassLevelList(
      classLevelId: json['ClassLevelId'] ?? 0,
      classLevelName: json['ClassLevelName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ClassLevelId': classLevelId,
      'ClassLevelName': classLevelName,
    };
  }
}

class SeriesList {
  final int seriesId;
  final String seriesName;

  SeriesList({
    required this.seriesId,
    required this.seriesName,
  });

  factory SeriesList.fromJson(Map<String, dynamic> json) {
    return SeriesList(
      seriesId: json['SeriesId'] ?? 0,
      seriesName: json['SeriesName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SeriesId': seriesId,
      'SeriesName': seriesName,
    };
  }
}
