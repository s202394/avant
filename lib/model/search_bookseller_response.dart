class SearchBooksellerResponse {
  final String status;
  final List<BookSellers>? bookSellers;

  SearchBooksellerResponse({
    required this.status,
    required this.bookSellers,
  });

  factory SearchBooksellerResponse.fromJson(Map<String, dynamic> json) {
    var bookSellersData = json["BookSellers"] as List?;
    List<BookSellers>? bookSellers;
    if (bookSellersData != null && bookSellersData.isNotEmpty) {
      bookSellers =
          bookSellersData.map((i) => BookSellers.fromJson(i)).toList();
    }

    return SearchBooksellerResponse(
      status: json['Status'] ?? '',
      bookSellers: bookSellers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Status': status,
      'BookSellers': bookSellers?.map((e) => e.toJson()).toList(),
    };
  }
}

class BookSellers {
  final int sNo;
  final String bookSellerName;
  final String address;
  final String city;
  final String state;
  final String country;
  final int action;

  BookSellers(
      {required this.sNo,
      required this.bookSellerName,
      required this.address,
      required this.city,
      required this.state,
      required this.country,
      required this.action});

  factory BookSellers.fromJson(Map<String, dynamic> json) {
    return BookSellers(
      sNo: json['SNo'] ?? '',
      bookSellerName: json['BookSellerName'] ?? '',
      address: json['Address'] ?? '',
      city: json['City'] ?? '',
      state: json['State'] ?? '',
      country: json['Country'] ?? '',
      action: json['Action'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SNo': sNo,
      'BookSellerName': bookSellerName,
      'Address': address,
      'City': city,
      'State': state,
      'Country': country,
      'Action': action,
    };
  }
}
