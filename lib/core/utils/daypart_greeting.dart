import '../worlds/daypart.dart';
import '../worlds/world.dart' show Daypart;

/// THIRTY's one daypart greeting, shared by the opening of every Circle and
/// the daily reminder: "Good morning, Thomas." with a first name, or
/// "Good morning." without one — never a stand-in like "friend".
///
/// The daypart is THIRTY's own ([daypartAt]: morning from 05:00, afternoon
/// from 12:00, evening from 18:00 until 05:00), so the greeting always
/// agrees with the World art shown at the same moment.
String daypartGreeting(DateTime localTime, {String? firstName}) {
  final greeting = switch (daypartAt(localTime)) {
    Daypart.morning => 'Good morning',
    Daypart.afternoon => 'Good afternoon',
    Daypart.evening => 'Good evening',
  };
  final name = firstName?.trim();
  return name == null || name.isEmpty ? '$greeting.' : '$greeting, $name.';
}
