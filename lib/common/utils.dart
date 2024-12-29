import 'package:flutter/services.dart';

import 'common.dart';

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

String getCode(String? input) {
  if (input != null && input.isNotEmpty) {
    String result = input.split(',')[0];
    if (result.isNotEmpty) {
      return '($result)';
    }
  }
  return '';
}

List<TextInputFormatter> getInputFormatters(String label) {
  if (label == 'Phone Number' ||
      label == 'Mobile' ||
      label == 'Mobile Number') {
    return [
      LengthLimitingTextInputFormatter(10),
      FilteringTextInputFormatter.digitsOnly,
    ];
  } else if (label == 'Pin Code') {
    return [
      LengthLimitingTextInputFormatter(6),
      FilteringTextInputFormatter.digitsOnly,
    ];
  } else if (label == 'Email Id' || label == 'Email') {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]')),
    ];
  } else if (label == 'PAN Number' || label == 'PAN') {
    return [
      LengthLimitingTextInputFormatter(10),
      FilteringTextInputFormatter.allow(
          RegExp(r'^[A-Z]{0,5}[0-9]{0,4}[A-Z]?$')),
    ];
  } else if (label == 'GST Number' || label == 'GST') {
    return [
      LengthLimitingTextInputFormatter(15),
      FilteringTextInputFormatter.allow(RegExp(
          r'^[0-9]{0,2}[A-Z]{0,5}[0-9]{0,4}[A-Z]{0,1}[1-9A-Z]{0,1}Z?[0-9A-Z]{0,1}$')),
    ];
  } else {
    return [];
  }
}

String? validateName(String label, String? value, String? mandatory) {
  if (mandatory == 'F' && label == 'Contact First Name') {
    if (value == null || value.isEmpty) {
      return 'Please enter $label';
    }
  } else if (mandatory == 'L' && label == 'Contact Last Name') {
    if (value == null || value.isEmpty) {
      return 'Please enter $label';
    }
  } else if (mandatory == 'B') {
    if ((label == 'Contact First Name' || label == 'Contact Last Name') &&
        (value == null || value.isEmpty)) {
      return 'Please enter $label';
    }
  }
  return null;
}

String? validatePhoneNumber(String label, String? value, String? mandatory) {
  if (mandatory == 'M' || mandatory == 'B') {
    if (value == null || value.isEmpty) {
      return 'Please enter Phone Number';
    }
    if (!Validator.isValidMobile(value)) {
      return 'Please enter valid Phone Number';
    }
  }
  return null;
}

String? validateEmail(
    String label, String? value, String? mandatory, bool isPhoneEmpty) {
  if (mandatory == 'E' || mandatory == 'B') {
    if (value == null || value.isEmpty) {
      return 'Please enter Email Id';
    }
    if (!Validator.isValidEmail(value)) {
      return 'Please enter valid Email Id';
    }
  }
  if (mandatory == 'A') {
    // Require at least one of Phone Number or Email
    if ((value == null || value.isEmpty) && isPhoneEmpty) {
      return 'Please enter at least one of Mobile Number or Email';
    }
  }
  return null;
}
