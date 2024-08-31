import 'package:flutter/material.dart';

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
              Image.network(
                widget.book.image,
                width: 100,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'images/book.png',
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                  );
                },
              ),
              const SizedBox(width: 16),
              // Book Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.book.author,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      widget.book.isbn,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      widget.book.bookType,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      widget.book.price,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _quantity == 0
                  ? SizedBox(
                      width: 115,
                      height: 40,
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
                          minimumSize: const Size(115, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    )
                  : SizedBox(
                      width: 115,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () {
                                if (_quantity > 0) {
                                  setState(() {
                                    _quantity--;
                                  });
                                  widget.onQuantityChanged(_quantity);
                                }
                              },
                            ),
                            Text('$_quantity'),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                setState(() {
                                  if (_quantity < 10) {
                                    _quantity++;
                                  }
                                });
                                widget.onQuantityChanged(_quantity);
                              },
                            ),
                          ],
                        ),
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
