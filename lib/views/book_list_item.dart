import 'package:avant/views/custom_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../model/fetch_titles_model.dart';

class BookListItem extends StatefulWidget {
  final TitleList book;
  final ValueChanged<int> onQuantityChanged;
  final bool areDropdownsSelected;
  final int maxQtyAllowed;

  const BookListItem({
    super.key,
    required this.book,
    required this.onQuantityChanged,
    required this.areDropdownsSelected,
    required this.maxQtyAllowed,
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

  void _updateQuantity(int newQuantity) {
    setState(() {
      _quantity = newQuantity;
    });
    widget.book.updateItemQuantity(widget.book, _quantity);
    widget.onQuantityChanged(_quantity);
    if (kDebugMode) {
      print('Quantity changed to: $_quantity');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color color = (widget.areDropdownsSelected && widget.maxQtyAllowed > 0)
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
                CustomText('Stock Available: ${widget.maxQtyAllowed}',
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
                                        widget.maxQtyAllowed > 0)
                                    ? () {
                                        _updateQuantity(_quantity + 1);
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
                                    Flexible(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (_quantity > 0) {
                                            _updateQuantity(_quantity - 1);
                                          }
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: const Text(
                                            '-',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        alignment: Alignment.center,
                                        color: Colors.red,
                                        child: Text(
                                          '$_quantity',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (_quantity <
                                              widget.maxQtyAllowed) {
                                            _updateQuantity(_quantity + 1);
                                          }
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: const Text(
                                            '+',
                                            style: TextStyle(
                                              fontSize: 17,
                                              color: Colors.red,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
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
        const Divider(),
      ],
    );
  }
}
