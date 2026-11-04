/// The local calendar date [date] falls on, as a `YYYY-MM-DD` string.
///
/// Shared by every piece of state that scopes itself to "today" in local
/// time — [`RecommendationNotifier`](../../features/home/application/recommendation_provider.dart),
/// [`FirstBreathNotifier`](../../features/home/application/first_breath_provider.dart),
/// and Batch 1's analytics instrumentation
/// (`core/analytics/analytics_service.dart`) — so all three agree on
/// exactly the same definition of "which day is it," rather than each
/// re-deriving it independently.
/// Whether [value] is a real local calendar date in exactly [dateKey]'s
/// `YYYY-MM-DD` form (audit remediation R6b, A2-09): four-digit year,
/// two-digit month and day, a date that exists ("2026-02-30" does not).
/// Never normalises — a value either is one or isn't.
bool isCanonicalDateKey(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return false;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1) return false;
  final date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

String dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
