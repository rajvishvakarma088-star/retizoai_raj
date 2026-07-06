// ignore_for_file: file_names

String formatAmount(dynamic value) {
  final num = double.tryParse(value?.toString() ?? '') ?? 0.0;
  final integer = num.truncate();
  final decimal = num - integer;

  if (decimal < 0.05) {
    return integer.toString();
  }

  if (decimal > 0.95) {
    return (integer + 1).toString();
  }

  final fixed = double.parse(num.toStringAsFixed(2));
  return fixed.toString();
}

double normalizeFormattedAmount(dynamic value) {
  return double.tryParse(formatAmount(value)) ?? 0.0;
}
