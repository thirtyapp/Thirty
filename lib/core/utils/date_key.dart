/// The local calendar date [date] falls on, as a `YYYY-MM-DD` string.
///
/// Shared by every piece of state that scopes itself to "today" in local
/// time — [`RecommendationNotifier`](../../features/home/application/recommendation_provider.dart),
/// [`FirstBreathNotifier`](../../features/home/application/first_breath_provider.dart),
/// and Batch 1's analytics instrumentation
/// (`core/analytics/analytics_service.dart`) — so all three agree on
/// exactly the same definition of "which day is it," rather than each
/// re-deriving it independently.
String dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
