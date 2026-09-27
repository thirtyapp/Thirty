import 'world.dart';

/// The [Daypart] for a device-local [localTime] (WORLD_SYSTEM.md §10,
/// "Daypart boundaries"): morning 05:00–11:59, afternoon 12:00–17:59,
/// evening 18:00–04:59 — evening therefore also covers night hours.
Daypart daypartAt(DateTime localTime) {
  final hour = localTime.hour;
  if (hour >= 5 && hour < 12) return Daypart.morning;
  if (hour >= 12 && hour < 18) return Daypart.afternoon;
  return Daypart.evening;
}
