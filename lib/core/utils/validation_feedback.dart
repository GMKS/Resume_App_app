import 'package:flutter/material.dart';

void showMissingFieldsSnackBar(
  BuildContext context,
  List<String> missingFields, {
  String prefix = 'Update the required fields before continuing:',
}) {
  final normalizedFields = missingFields
      .map((field) => field.trim())
      .where((field) => field.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  if (normalizedFields.isEmpty) {
    return;
  }

  final message = '$prefix ${normalizedFields.join(', ')}';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
}
