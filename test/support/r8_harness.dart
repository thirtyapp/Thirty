import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:thirty/core/premium/entitlement_status.dart';
import 'package:thirty/core/premium/premium_access.dart';
import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/features/home/application/circle_history_deletion.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';

import 'r8_fault_disk.dart';

/// A settable billing answer, standing for RevenueCat's verified one.
class SettableEntitlement extends EntitlementNotifier {
  SettableEntitlement(this._initial);
  final EntitlementStatus _initial;
  @override
  EntitlementStatus build() => _initial;
  void set(EntitlementStatus s) => state = s;
}

/// A clock the test moves.
class TestClock {
  TestClock(this.value);
  DateTime value;
}

/// Audit remediation R8 — production providers on the real
/// [SharedPreferences] over a [FaultDisk]. A restart is a new process on
/// what reached the disk, after `main.dart`'s start-up deletion step.
class R8Harness {
  R8Harness(DateTime at) : clock = TestClock(at);

  final TestClock clock;
  late FaultDisk disk;
  late SharedPreferences prefs;

  Future<void> boot([Map<String, Object> stored = const {}]) async {
    disk = FaultDisk(stored);
    SharedPreferencesStorePlatform.instance = disk;
    SharedPreferences.resetStatic();
    prefs = await SharedPreferences.getInstance();
  }

  /// A new process on what reached the disk — the disk's faults healed, as
  /// after a reboot, unless [keepFaults].
  Future<void> restart({bool keepFaults = false}) async {
    final before = disk;
    await boot(await before.stored());
    if (keepFaults) {
      disk = before;
      SharedPreferencesStorePlatform.instance = before;
      SharedPreferences.resetStatic();
      prefs = await SharedPreferences.getInstance();
    }
    try {
      await completeInterruptedHistoryDeletion(prefs);
    } catch (_) {
      // main.dart carries on; the intent stays recorded.
    }
  }

  ProviderContainer open({
    EntitlementStatus status = EntitlementStatus.active,
    List<Override> overrides = const [],
  }) {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        nowProvider.overrideWith((ref) => clock.value),
        eventClockProvider.overrideWithValue(() => clock.value),
        entitlementStatusProvider.overrideWith(
          () => SettableEntitlement(status),
        ),
        safetyPendingAllowedProvider.overrideWithValue(false),
        ...overrides,
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Lets every queued write run.
  static Future<void> settle() async {
    for (var i = 0; i < 60; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}
