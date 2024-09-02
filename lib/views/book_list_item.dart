import 'package:flutter/material.dart';

import '../api/api_constants.dart';
import '../model/fetch_titles_model.dart';

class BookListItem extends StatefulWidget {
  final TitleList book;
  final ValueChanged<int> onQuantityChanged;

  const BookListItem({
    super.key,
    required this.book,
    required this.onQuantityChanged,
  });

  @override
  BookListItemState createState() => BookListItemState();
}

class BookListItemState extends State<BookListItem> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.book.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ensure the image has a fixed size and does not overflow
              SizedBox(
                width: 100,
                height: 120,
                child: Image.network(
                  '$imageUrl${widget.book.image}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'images/book.png',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Book Details in an Expanded widget to take up available space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.book.author,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      widget.book.isbn,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      widget.book.bookType,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      widget.book.price,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Stack to overlay Add button and Quantity control
              SizedBox(
                width: 100,
                height: 40,
                child: Stack(
                  children: [
                    _quantity == 0
                        ? Positioned.fill(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                                widget.onQuantityChanged(_quantity);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(100, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: const Text('Add'),
                            ),
                          )
                        : Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 30,
                                    height: 40,
                                    child: IconButton(
                                      icon: const Icon(Icons.remove,
                                          size: 18, color: Colors.red),
                                      onPressed: () {
                                        if (_quantity > 0) {
                                          setState(() {
                                            _quantity--;
                                          });
                                          widget.onQuantityChanged(_quantity);
                                        }
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 40,
                                      alignment: Alignment.center,
                                      color: Colors.red,
                                      child: Text(
                                        '$_quantity',
                                        style: const TextStyle(
                                            color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    height: 40,
                                    child: IconButton(
                                      icon: const Icon(Icons.add,
                                          size: 18, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          if (_quantity < 10) {
                                            _quantity++;
                                          }
                                        });
                                        widget.onQuantityChanged(_quantity);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}
