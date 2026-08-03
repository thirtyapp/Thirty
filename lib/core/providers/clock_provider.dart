import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current moment. Call sites read this instead of calling
/// `DateTime.now()` directly, so date-dependent logic (e.g. "has today's
/// ritual already happened?") stays deterministic and overridable in tests.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());
