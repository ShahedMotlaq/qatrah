import 'package:flutter/material.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';

DataColumn buildDataColumn(
  BuildContext context, {
  required String label,
  double columnWithFraction = .1,
}) {
  final theme = context.theme;
  return DataColumn(
    headingRowAlignment: MainAxisAlignment.center,
    label: FittedBox(
      child: Text(
        label,
        style: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
