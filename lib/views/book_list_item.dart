import 'package:flutter/material.dart';

import '../model/fetch_titles_model.dart';

class BookListItem extends StatefulWidget {
  final TitleList book;
  final ValueChanged<int> onQuantityChanged;
  final bool areDropdownsSelected;

  const BookListItem({
    super.key,
    required this.book,
    required this.onQuantityChanged,
    required this.areDropdownsSelected,
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
              // Image on the left side
              SizedBox(
                width: 100,
                height: 120,
                child: widget.book.image.isEmpty
                    ? const Icon(Icons.book_outlined,
                        size: 48, color: Colors.grey)
                    : Image.network(
                        widget.book.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child; // The image has finished loading.
                          } else {
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            );
                          }
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.book,
                              size: 48, color: Colors.grey);
                        },
                      ),
              ),
              const SizedBox(width: 8),
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
              Column(
                children: [
                  Text(
                    'Stock Available: ${widget.book.physicalStock}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: Stack(
                      children: [
                        _quantity == 0
                            ? Positioned.fill(
                                child: ElevatedButton(
                                  onPressed: widget.areDropdownsSelected
                                      ? () {
                                          if (_quantity <
                                              widget.book.physicalStock) {
                                            _quantity++;
                                          }
                                          widget.onQuantityChanged(_quantity);
                                        }
                                      : null,
                                  // Disable the button if the dropdowns are not selected
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
                                              widget
                                                  .onQuantityChanged(_quantity);
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
                                              if (_quantity <
                                                  widget.book.physicalStock) {
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
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}
