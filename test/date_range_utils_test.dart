import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder/features/editor/utils/date_range_utils.dart';

void main() {
  test('date ranges do not overlap when one starts the day after another ends', () {
    final firstStart = DateTime(2016, 4, 4);
    final firstEnd = DateTime(2020, 4, 4);
    final secondStart = DateTime(2012, 5, 6);
    final secondEnd = DateTime(2016, 4, 3);

    expect(
      dateRangesOverlap(
        startA: firstStart,
        endA: firstEnd,
        startB: secondStart,
        endB: secondEnd,
      ),
      isFalse,
    );
  });

  test('date ranges overlap when they share the same boundary day', () {
    final firstStart = DateTime(2016, 4, 3);
    final firstEnd = DateTime(2020, 4, 4);
    final secondStart = DateTime(2012, 5, 6);
    final secondEnd = DateTime(2016, 4, 3);

    expect(
      dateRangesOverlap(
        startA: firstStart,
        endA: firstEnd,
        startB: secondStart,
        endB: secondEnd,
      ),
      isTrue,
    );
  });

  test('resolved current range end uses provided today value', () {
    expect(
      resolvedDateRangeEnd(
        startDate: DateTime(2024, 1, 1),
        endDate: null,
        isCurrent: true,
        today: DateTime(2026, 4, 18, 15, 30),
      ),
      DateTime(2026, 4, 18),
    );
  });

  test('resolved non-current range end falls back to the start date', () {
    expect(
      resolvedDateRangeEnd(
        startDate: DateTime(2024, 1, 1),
        endDate: null,
        isCurrent: false,
      ),
      DateTime(2024, 1, 1),
    );
  });
}