int extractNumericPart(String input) {
  return int.parse(input.replaceAll(RegExp(r'[^0-9]'), ''));
}

String extractStringPart(String input) {
  return input.replaceAll(RegExp(r'[0-9]'), '');
}

bool isNumeric(String input) {
  final numericRegex = RegExp(r'^-?[0-9]+$');
  return numericRegex.hasMatch(input);
}
