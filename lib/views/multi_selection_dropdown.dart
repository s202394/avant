import 'package:avant/views/custom_text.dart';
import 'package:flutter/material.dart';

class MultiSelectDropdown<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) itemLabelBuilder;
  final ValueChanged<List<T>> onChanged;
  final bool isMandatory;
  final bool isSubmitted;

  const MultiSelectDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.itemLabelBuilder,
    required this.onChanged,
    required this.isMandatory,
    required this.isSubmitted,
  });

  @override
  MultiSelectDropdownState<T> createState() => MultiSelectDropdownState<T>();
}

class MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    // Initialize selected items with default values
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: PopupMenuButton<T>(
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
                  Expanded(
                    child: CustomText(
                      widget.itemLabelBuilder(item),
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
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
              labelStyle: const TextStyle(fontSize: 14),
              errorText: widget.isMandatory &&
                      _selectedItems.isEmpty &&
                      widget.isSubmitted
                  ? 'Please select ${widget.label}'
                  : null,
            ),
            child: DropdownButtonHideUnderline(
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      _selectedItems.isNotEmpty
                          ? _selectedItems
                              .map(widget.itemLabelBuilder)
                              .join(', ')
                          : 'Select',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
