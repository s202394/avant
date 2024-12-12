int extractNumericPart(String input) {
  // Remove all non-numeric characters
  String numericPart = input.replaceAll(RegExp(r'[^0-9]'), '');

  // Check if the resulting string is empty
  if (numericPart.isEmpty) {
    return 0; // Default value when no numeric part is found
  }

  // Parse and return the number
  return int.parse(numericPart);
}

String extractStringPart(String input) {
  return input.replaceAll(RegExp(r'[0-9]'), '');
}

bool isNumeric(String input) {
  final numericRegex = RegExp(r'^-?[0-9]+$');
  return numericRegex.hasMatch(input);
}
