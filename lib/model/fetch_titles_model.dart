class FetchTitlesResponse {
  final String status;
  final List<TitleList>? titleList;

  FetchTitlesResponse({
    required this.status,
    required this.titleList,
  });

  factory FetchTitlesResponse.fromJson(Map<String, dynamic> json) {
    var titleListData = json["TitleList"] as List?;
    List<TitleList>? titleList;
    if (titleListData != null && titleListData.isNotEmpty) {
      titleList = titleListData.map((i) => TitleList.fromJson(i)).toList();
    }

    return FetchTitlesResponse(
      status: json['Status'] ?? '',
      titleList: titleList,
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
  final String price;
  final double listPrice;
  final String bookNum;
  final String image;
  final String bookType;
  final String imageUrl;
  final int physicalStock;
  int quantity;

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
    required this.imageUrl,
    required this.physicalStock,
    this.quantity = 0,
  });

  factory TitleList.fromJson(Map<String, dynamic> json) {
    return TitleList(
      bookId: json['BookId'] ?? 0,
      title: json['Title'] ?? '',
      isbn: json['ISBN'] ?? '',
      author: json['Author'] ?? '',
      price: json['Price'] ?? '',
      listPrice: json['ListPrice'] ?? 0,
      bookNum: json['Booknum'] ?? '',
      image: json['Image'] ?? '',
      bookType: json['BookType'] ?? '',
      imageUrl: json['ImageUrl'] ?? '',
      physicalStock: json['PhysicalStock'] ?? 0,
      quantity: 0,
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
      'Booknum': bookNum,
      'Image': image,
      'BookType': bookType,
      'Quantity': quantity,
      'ImageUrl': quantity,
      'PhysicalStock': quantity,
    };
  }
}
