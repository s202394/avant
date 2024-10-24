import 'package:avant/views/custom_text.dart';
import 'package:avant/views/label_text.dart';
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
  late List<T> _tempSelectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: PopupMenuButton<void>(
        onSelected: (_) {},
        itemBuilder: (context) {
          _tempSelectedItems = List.from(_selectedItems); // Temporary selection
          return [
            PopupMenuItem<void>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Container(
                    width:
                        MediaQuery.of(context).size.width * 0.8, // Adjust width
                    padding: const EdgeInsets.all(5.0), // Add padding
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Add a title (optional)
                        CustomText(
                          widget.label,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        const Divider(),
                        // List of items with better styling
                        SingleChildScrollView(
                          child: Column(
                            children: widget.items.map((item) {
                              return CheckboxListTile(
                                value: _tempSelectedItems.contains(item),
                                title: CustomText(
                                  widget.itemLabelBuilder(item),
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _tempSelectedItems.add(item);
                                    } else {
                                      _tempSelectedItems.remove(item);
                                    }
                                  });
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 0.0, vertical: 0.0),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ),
                        const Divider(),
                        // Add OK and Cancel buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Discard selection and close the popup
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                // Confirm selection
                                setState(() {
                                  _selectedItems =
                                      List.from(_tempSelectedItems);
                                  widget.onChanged(_selectedItems);
                                });
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ];
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
                    child: Text(
                      _selectedItems.isNotEmpty
                          ? _selectedItems
                              .map(widget.itemLabelBuilder)
                              .join(', ')
                          : 'Select',
                      style: const TextStyle(fontSize: 14, color: Colors.black),
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
