import 'package:flutter/material.dart';

class DynamicDropdownCell<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<Map<T, String>> items;
  final Function(T?) onChanged;

  const DynamicDropdownCell({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        value: value,
        hint: Text(
          hint,
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item.keys.first, // Use the ID (key)
            child: Text(
              item.values.first, // Display the name (value)
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }
}
