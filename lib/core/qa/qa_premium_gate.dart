import 'package:flutter/foundation.dart';

/// QA-1 — the debug-only Premium QA harness's one activation gate.
///
/// The harness exists only when **both** the build is a debug build
/// ([kDebugMode]) **and** it was launched with
/// `--dart-define=THIRTY_QA_PREMIUM=true`. Profile and release builds can
/// never satisfy [kDebugMode], so the harness — its entitlement override,
/// its synthetic history and its controls — is unreachable there whatever
/// the flag says, and [kQaPremiumHarnessEnabled] being a compile-time
/// `false` lets those builds tree-shake it away entirely.
///
/// A debug build without the flag behaves exactly as it does without this
/// file: `main.dart` checks [kQaPremiumHarnessEnabled] once and otherwise
/// takes its unchanged production path.
const qaPremiumFlag = bool.fromEnvironment('THIRTY_QA_PREMIUM');

/// The gate itself, kept as a pure function of its two inputs so it can be
/// verified directly for every build mode — `kDebugMode` is a compile-time
/// constant that a single test run cannot vary.
bool qaPremiumHarnessAllowed({
  required bool debugMode,
  required bool flagEnabled,
}) => debugMode && flagEnabled;

/// The only value production code reads: [qaPremiumHarnessAllowed] at the
/// compile-time boundary.
const bool kQaPremiumHarnessEnabled = kDebugMode && qaPremiumFlag;
