DateTime dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime resolvedDateRangeEnd({
  required DateTime startDate,
  DateTime? endDate,
  required bool isCurrent,
  DateTime? today,
}) {
  if (isCurrent) {
    return dateOnly(today ?? DateTime.now());
  }

  return dateOnly(endDate ?? startDate);
}

bool dateRangesOverlap({
  required DateTime startA,
  required DateTime endA,
  required DateTime startB,
  required DateTime endB,
}) {
  var normalizedStartA = dateOnly(startA);
  var normalizedEndA = dateOnly(endA);
  var normalizedStartB = dateOnly(startB);
  var normalizedEndB = dateOnly(endB);

  if (normalizedEndA.isBefore(normalizedStartA)) {
    final originalStartA = normalizedStartA;
    normalizedStartA = normalizedEndA;
    normalizedEndA = originalStartA;
  }

  if (normalizedEndB.isBefore(normalizedStartB)) {
    final originalStartB = normalizedStartB;
    normalizedStartB = normalizedEndB;
    normalizedEndB = originalStartB;
  }

  return !normalizedEndA.isBefore(normalizedStartB) &&
      !normalizedStartA.isAfter(normalizedEndB);
}