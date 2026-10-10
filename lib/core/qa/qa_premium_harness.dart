import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/reminder/application/reminder_provider.dart';
import '../app/thirty_app.dart';
import '../premium/premium_access.dart';
import '../routing/app_router.dart';
import 'qa_container.dart';
import 'qa_entitlement_gateway.dart';
import 'qa_scenario.dart';

/// QA-1 — the debug-only Premium QA harness around [ThirtyApp].
///
/// `main.dart` runs this instead of its normal root only when
/// `kQaPremiumHarnessEnabled` is true. It starts in the normal state (the
/// genuine store, the normal entitlement gateway) and changes nothing until
/// the tester explicitly applies a selection from the QA panel. Every
/// session — each Apply, and Reset — is a fresh app start: a new container
/// over an isolated [QaSession] (or over the genuine store again on Reset),
/// a new router, and a newly keyed app subtree, so no data, route, page or
/// message from the previous session survives. The previous container and
/// router are simply discarded.
class QaPremiumHarnessApp extends StatefulWidget {
  const QaPremiumHarnessApp({
    super.key,
    required this.genuinePreferences,
    required this.supabaseAvailable,
    this.clock = DateTime.now,
  });

  final SharedPreferences genuinePreferences;
  final bool supabaseAvailable;

  /// The reference moment synthetic history is built back from.
  final DateTime Function() clock;

  @override
  State<QaPremiumHarnessApp> createState() => _QaPremiumHarnessAppState();
}

class _QaPremiumHarnessAppState extends State<QaPremiumHarnessApp> {
  late ProviderContainer _container;
  late GoRouter _router;
  QaSession? _session;
  var _generation = 0;
  var _applying = false;

  @override
  void initState() {
    super.initState();
    _container = _startContainer(null);
    _router = createAppRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    _container.dispose();
    super.dispose();
  }

  /// Mirrors `main.dart`'s startup for the given session.
  ProviderContainer _startContainer(QaSession? session) {
    final container = ProviderContainer(
      overrides: qaContainerOverrides(
        genuinePreferences: widget.genuinePreferences,
        supabaseAvailable: widget.supabaseAvailable,
        session: session,
      ),
    );
    unawaited(container.read(entitlementStatusProvider.notifier).initialize());
    unawaited(container.read(reminderProvider.notifier).initialize());
    return container;
  }

  void _switchTo(QaSession? session) {
    final previousContainer = _container;
    final previousRouter = _router;
    setState(() {
      _session = session;
      _container = _startContainer(session);
      _router = createAppRouter(initialLocation: session?.scenario.opensAt);
      _generation++;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousRouter.dispose();
      previousContainer.dispose();
    });
  }

  Future<void> _apply(QaEntitlement entitlement, QaScenario scenario) async {
    setState(() => _applying = true);
    final store = await buildQaStore(
      scenario: scenario,
      genuine: widget.genuinePreferences,
      referenceNow: widget.clock(),
    );
    if (!mounted) return;
    _applying = false;
    _switchTo(
      QaSession(
        entitlement: scenario.fixedEntitlement ?? entitlement,
        scenario: scenario,
        store: store,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      key: ValueKey(_generation),
      container: _container,
      child: ThirtyApp(
        router: _router,
        builder: (context, child) => QaHarnessOverlay(
          session: _session,
          applying: _applying,
          onApply: _apply,
          onReset: () => _switchTo(null),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// The persistent QA marker over every screen, and the QA panel it opens.
/// Deliberately loud and unpolished: nothing here is production UI.
class QaHarnessOverlay extends StatefulWidget {
  const QaHarnessOverlay({
    super.key,
    required this.session,
    required this.applying,
    required this.onApply,
    required this.onReset,
    required this.child,
  });

  final QaSession? session;
  final bool applying;
  final void Function(QaEntitlement, QaScenario) onApply;
  final VoidCallback onReset;
  final Widget child;

  @override
  State<QaHarnessOverlay> createState() => _QaHarnessOverlayState();
}

/// The marker's two lines for [session] — see [QaHarnessOverlay].
(String, String) qaMarkerLines(QaSession? session) {
  if (session == null) {
    return ('QA PREMIUM · OFF', 'REAL DATA · tap to set up');
  }
  final data = session.scenario == QaScenario.none
      ? 'QA SANDBOX · copy of real data'
      : 'QA DATA · ${session.scenario.wireName}';
  return ('QA PREMIUM · ${session.entitlement.label}', data);
}

class _QaHarnessOverlayState extends State<QaHarnessOverlay> {
  var _panelOpen = false;
  late QaEntitlement _entitlement;
  late QaScenario _scenario;

  static const _markerColor = Color(0xFFD5006D);

  @override
  void initState() {
    super.initState();
    _entitlement = widget.session?.entitlement ?? QaEntitlement.active;
    _scenario = widget.session?.scenario ?? QaScenario.newUser;
  }

  @override
  Widget build(BuildContext context) {
    final (title, data) = qaMarkerLines(widget.session);
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: top + 2,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              key: const Key('qa-marker'),
              onTap: () => setState(() => _panelOpen = !_panelOpen),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _markerColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(title), Text(data)],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_panelOpen)
          Positioned(
            top: top + 34,
            left: 12,
            right: 12,
            child: _buildPanel(context),
          ),
      ],
    );
  }

  Widget _buildPanel(BuildContext context) {
    final fixed = _scenario.fixedEntitlement;
    final entitlement = fixed ?? _entitlement;

    return Material(
      key: const Key('qa-panel'),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _markerColor, width: 2),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black, fontSize: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QA-1 PREMIUM HARNESS — debug only',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _markerColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Entitlement'),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final option in QaEntitlement.values)
                      ChoiceChip(
                        key: Key('qa-entitlement-${option.name}'),
                        label: Text(option.label),
                        selected: entitlement == option,
                        onSelected: fixed != null
                            ? null
                            : (_) => setState(() => _entitlement = option),
                      ),
                  ],
                ),
                if (fixed != null)
                  const Text(
                    'Lapsed is inactive by definition.',
                    style: TextStyle(fontSize: 11),
                  ),
                const SizedBox(height: 8),
                const Text('Scenario'),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final option in QaScenario.values)
                      ChoiceChip(
                        key: Key('qa-scenario-${option.wireName}'),
                        label: Text(option.label),
                        selected: _scenario == option,
                        onSelected: (_) => setState(() => _scenario = option),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilledButton(
                      key: const Key('qa-apply'),
                      onPressed: widget.applying
                          ? null
                          : () {
                              setState(() => _panelOpen = false);
                              widget.onApply(entitlement, _scenario);
                            },
                      child: Text(widget.applying ? 'Applying…' : 'Apply'),
                    ),
                    OutlinedButton(
                      key: const Key('qa-reset'),
                      onPressed: widget.session == null
                          ? null
                          : () {
                              setState(() => _panelOpen = false);
                              widget.onReset();
                            },
                      child: const Text('Reset to real'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _panelOpen = false),
                      child: const Text('Close'),
                    ),
                  ],
                ),
                const Text(
                  'Applying never writes to, and reset never deletes, the '
                  "device's real THIRTY data.",
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
