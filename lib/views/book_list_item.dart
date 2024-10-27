import 'package:avant/views/custom_text.dart';
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
    Color color = (widget.areDropdownsSelected && widget.book.physicalStock > 0)
        ? Colors.white
        : Colors.black;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image on the left side
            SizedBox(
              width: 70,
              height: 80,
              child: widget.book.image.isEmpty
                  ? const Icon(Icons.book_outlined,
                      size: 40, color: Colors.grey)
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
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
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
                  CustomText(widget.book.title,
                      fontSize: 13, fontWeight: FontWeight.bold),
                  CustomText(widget.book.author,
                      fontSize: 11, color: Colors.grey),
                  CustomText(widget.book.isbn,
                      fontSize: 11, color: Colors.grey),
                  CustomText(widget.book.bookType,
                      fontSize: 11, color: Colors.grey),
                  CustomText(widget.book.price,
                      fontSize: 11, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                CustomText('Stock Available: ${widget.book.physicalStock}',
                    fontSize: 8),
                const SizedBox(height: 8),
                SizedBox(
                  width: 75,
                  height: 25,
                  child: Stack(
                    children: [
                      _quantity == 0
                          ? Positioned.fill(
                              child: ElevatedButton(
                                onPressed: (widget.areDropdownsSelected &&
                                        widget.book.physicalStock > 0)
                                    ? () {
                                        if (_quantity <
                                            widget.book.physicalStock) {
                                          setState(() {
                                            _quantity++;
                                          });
                                        }
                                        widget.onQuantityChanged(_quantity);
                                        print('Quantity changed to: $_quantity');
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(75, 25),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: CustomText('Add',
                                    fontSize: 10, color: color),
                              ),
                            )
                          : Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        // Decrement quantity if greater than zero
                                        if (_quantity > 0) {
                                          setState(() {
                                            _quantity--;
                                          });
                                          widget.onQuantityChanged(_quantity);
                                        }
                                      },
                                      child: const Text('-', style: TextStyle(fontSize: 20)),
                                    ),
                                    Text('$_quantity'),
                                    GestureDetector(
                                      onTap: () {
                                        // Increment quantity
                                        if (_quantity < widget.book.physicalStock) {
                                          setState(() {
                                            _quantity++;
                                          });
                                          widget.onQuantityChanged(_quantity);
                                        }
                                      },
                                      child: const Text('+', style: TextStyle(fontSize: 20)),
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
        const Divider(),
      ],
    );
  }
}
