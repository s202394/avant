import 'package:flutter/material.dart';

class MultiSelectDropdown<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) itemLabelBuilder;
  final ValueChanged<List<T>> onChanged;
  final bool  isSubmitted;

  const MultiSelectDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.itemLabelBuilder,
    required this.onChanged,
    required this.isSubmitted,
  });

  @override
  _MultiSelectDropdownState<T> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
        onSelected: (item) {
          setState(() {
            if (_selectedItems.contains(item)) {
              _selectedItems.remove(item);
            } else {
              _selectedItems.add(item);
            }
            widget.onChanged(_selectedItems);
          });
        },
        itemBuilder: (context) {
          return widget.items.map((item) {
            return PopupMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedItems.contains(item),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedItems.add(item);
                        } else {
                          _selectedItems.remove(item);
                        }
                        widget.onChanged(_selectedItems);
                      });
                    },
                  ),
                  Text(widget.itemLabelBuilder(item)),
                ],
              ),
            );
          }).toList();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              errorText: _selectedItems.isEmpty&& widget.isSubmitted
                  ? 'Please select a ${widget.label}'
                  : null,
            ),
            child: DropdownButtonHideUnderline(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedItems.isNotEmpty
                          ? _selectedItems
                              .map(widget.itemLabelBuilder)
                              .join(', ')
                          : '',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ));
  }
}
