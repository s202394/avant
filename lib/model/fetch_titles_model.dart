class FetchTitlesResponse {
  final String status;
  final List<TitleList> titleList;

  FetchTitlesResponse({
    required this.status,
    required this.titleList,
  });

  factory FetchTitlesResponse.fromJson(Map<String, dynamic> json) {
    var listTitle = json["TitleList"] as List;
    List<TitleList> list = listTitle.map((i) => TitleList.fromJson(i)).toList();

    return FetchTitlesResponse(
      status: json['Status'] ?? '',
      titleList: list,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'TitleList': titleList?.map((e) => e.toJson()).toList(),
    };
  }
}

class TitleList {
  final int bookId;
  final String title;
  final String isbn;
  final String author;
  final double price;
  final double listPrice;
  final String bookNum;
  final String image;
  final String bookType;

  TitleList({
    required this.bookId,
    required this.title,
    required this.isbn,
    required this.author,
    required this.price,
    required this.listPrice,
    required this.bookNum,
    required this.image,
    required this.bookType,
  });

  factory TitleList.fromJson(Map<String, dynamic> json) {
    return TitleList(
      bookId: json['BookId'] ?? 0,
      title: json['Title'] ?? '',
      isbn: json['ISBN'] ?? '',
      author: json['Author'] ?? '',
      price: json['Price'] ?? 0,
      listPrice: json['ListPrice'] ?? 0,
      bookNum: json['BookNum'] ?? '',
      image: json['Image'] ?? '',
      bookType: json['BookType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BookId': bookId,
      'Title': title,
      'ISBN': isbn,
      'Author': author,
      'Price': price,
      'ListPrice': listPrice,
      'BookNum': bookNum,
      'Image': image,
      'BookType': bookType,
    };
  }
}
