import 'package:flutter_test/flutter_test.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/toolkit/domain/module_library.dart';
import 'package:thirty/features/toolkit/domain/path_catalog.dart';
import 'package:thirty/features/toolkit/domain/path_engine.dart';

/// V2 Phase D — the module library and the launch Paths (ADR-022): only
/// live content, truthful lengths, levels that differ in substance, and six
/// Paths with six different jobs.
void main() {
  group('modules', () {
    test('every module comes from a live activity — never content awaiting '
        'the safety review, never a retired one', () {
      for (final module in moduleLibrary.values) {
        expect(
          module.activity.status,
          ActivityStatus.live,
          reason: module.id.name,
        );
      }
      // The gated and retired activities stay out.
      final sources = {for (final m in moduleLibrary.values) m.source};
      for (final gated in [
        ActivityId.briskStepBurst,
        ActivityId.activeMovementSnack,
        ActivityId.focusedBreathingCount,
        ActivityId.restfulBreathingPause,
        ActivityId.energisingBreathReset,
      ]) {
        expect(sources, isNot(contains(gated)), reason: gated.name);
      }
    });

    test('lengths are truthful: never below the activity\'s own minimum, '
        'never above its natural length; a Guided piece has one length', () {
      for (final module in moduleLibrary.values) {
        final activity = module.activity;
        expect(
          module.shortMinutes,
          greaterThanOrEqualTo(activity.minMinutes),
          reason: module.id.name,
        );
        expect(
          module.fullMinutes,
          lessThanOrEqualTo(activity.typicalMinutes),
          reason: module.id.name,
        );
        if (module.guided) {
          expect(module.hasShortForm, isFalse, reason: module.id.name);
          expect(
            module.fullMinutes,
            activity.typicalMinutes,
            reason: module.id.name,
          );
        }
      }
    });

    test('level 1 differs in substance from level 2: a shorter length and its '
        'own, shorter instruction — never just longer copy', () {
      for (final module in moduleLibrary.values) {
        if (!module.hasShortForm) continue;
        expect(
          module.shortMinutes,
          lessThan(module.fullMinutes),
          reason: module.id.name,
        );
        expect(module.shortInstruction, isNotNull, reason: module.id.name);
        expect(module.fullInstruction, isNotNull, reason: module.id.name);
        expect(
          module.shortInstruction,
          isNot(module.fullInstruction),
          reason: module.id.name,
        );
      }
    });

    test('every module earns its place: each is used by a Path', () {
      final used = {for (final template in pathCatalog) ...template.pool};
      expect(used, moduleLibrary.keys.toSet());
    });

    test('a module use round-trips; a short form a module lacks is its one '
        'length', () {
      for (final module in moduleLibrary.values) {
        for (final short in [true, false]) {
          final use = ModuleUse(module.id, short: short);
          final back = ModuleUse.fromWire(use.wire)!;
          expect(back.module, module.id);
          expect(back.short, short && module.hasShortForm);
        }
      }
      expect(ModuleUse.fromWire('nope:short'), isNull);
      expect(ModuleUse.fromWire('musicMove:tiny'), isNull);
      expect(ModuleUse.fromWire(3), isNull);
    });
  });

  group('compositions', () {
    test('pieces are joined openers first, then main, then closers — '
        'stably, whatever order they were given in', () {
      final a = Composition(const [
        ModuleUse(ModuleId.musicMove, short: false),
        ModuleUse(ModuleId.standingStretch, short: false),
      ]);
      expect(a.uses.map((u) => u.module), [
        ModuleId.standingStretch,
        ModuleId.musicMove,
      ]);
      final openers = Composition(const [
        ModuleUse(ModuleId.warmDrink, short: false),
        ModuleUse(ModuleId.gentleStretch, short: false),
      ]);
      expect(openers.uses.map((u) => u.module), [
        ModuleId.warmDrink,
        ModuleId.gentleStretch,
      ]);
    });

    test('a joined Circle runs on the Guided runtime: an Open piece is one '
        'part, a Guided piece brings its own steps; its length is the sum, '
        'its ending the last piece\'s', () {
      final composition = Composition(const [
        ModuleUse(ModuleId.standingStretch, short: false),
        ModuleUse(ModuleId.musicMove, short: true),
      ]);
      expect(composition.minutes, 10);
      final session = sessionFor(composition, title: 'My pick-me-up');
      expect(session.title, 'My pick-me-up');
      expect(session.mode, CircleMode.guidedSteps);
      expect(session.typicalMinutes, 10);
      final stretchSteps = activityDefinition(
        ActivityId.energisingStretchFlow,
      ).steps;
      expect(session.steps.length, stretchSteps.length + 1);
      expect(session.steps.last.name, 'Move to music');
      expect(session.steps.last.cue, 'About 5 minutes');
      expect(session.ending, activityDefinition(ActivityId.moveToMusic).ending);
      expect(session.safetyNote, isNotNull);
    });

    test('compositions round-trip their wire form', () {
      final composition = Composition(const [
        ModuleUse(ModuleId.writeDown, short: true),
        ModuleUse(ModuleId.clearSurface, short: false),
      ]);
      expect(Composition.fromWire(composition.toWire()), composition);
      expect(Composition.fromWire(const <Object?>[]), isNull);
      expect(Composition.fromWire(['writeDown:short', 'bad']), isNull);
    });
  });

  group('Paths', () {
    test('six, two per need, each with three different pieces that fit it', () {
      expect(pathCatalog, hasLength(6));
      for (final need in Intention.values) {
        expect(pathsFor(need), hasLength(2), reason: need.name);
      }
      for (final template in pathCatalog) {
        expect(template.pool.toSet(), hasLength(3), reason: template.name);
        for (final module in template.pool) {
          expect(
            moduleOf(module).fitFor(template.need),
            isNot(NeedFit.none),
            reason: '${template.name}: ${module.name}',
          );
        }
      }
    });

    test('six distinct jobs: no two Paths share their two lead pieces, and '
        'every name and promise is different', () {
      final leads = {
        for (final t in pathCatalog) {t.pool[0], t.pool[1]},
      };
      expect(leads, hasLength(6));
      expect({for (final t in pathCatalog) t.name}, hasLength(6));
      expect({for (final t in pathCatalog) t.building}, hasLength(6));
      expect({for (final t in pathCatalog) t.routineName}, hasLength(6));
    });

    test('any two pieces of a Path join within 30 minutes', () {
      for (final template in pathCatalog) {
        final pool = template.pool;
        for (var i = 0; i < pool.length; i++) {
          for (var j = 0; j < pool.length; j++) {
            if (i == j) continue;
            final together = fullTogether(pool[i], pool[j]);
            expect(
              together,
              isNotNull,
              reason: '${template.name}: ${pool[i].name} + ${pool[j].name}',
            );
            expect(together!.minutes, lessThanOrEqualTo(maxCircleMinutes));
          }
        }
      }
    });

    test('no copy says AI, completed, streak or score', () {
      final copy = [
        for (final t in pathCatalog) ...[t.name, t.building, t.routineName],
        for (final m in moduleLibrary.values) ...[
          m.name,
          m.purpose,
          ?m.shortInstruction,
          ?m.fullInstruction,
        ],
      ].join(' ').toLowerCase();
      for (final word in ['ai ', 'complete', 'streak', 'score', 'level']) {
        expect(copy, isNot(contains(word)), reason: word);
      }
    });
  });
}
