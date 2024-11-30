int extractNumericPart(String input) {
  return int.parse(input.replaceAll(RegExp(r'[^0-9]'), ''));
}

String extractStringPart(String input) {
  return input.replaceAll(RegExp(r'[0-9]'), '');
}
