import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thirty/core/providers/clock_provider.dart';
import 'package:thirty/core/providers/shared_preferences_provider.dart';
import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_button.dart';
import 'package:thirty/features/home/application/activity_catalog.dart';
import 'package:thirty/features/home/application/circle_journal.dart';
import 'package:thirty/features/home/application/recommendation_provider.dart';
import 'package:thirty/features/home/presentation/home_page.dart';
import 'package:thirty/features/home/presentation/widgets/journal_data_controls.dart';

/// Large-text accessibility foundation for [ThirtyButton], measured with
/// the app's real fonts: 48pt / 56pt are minimum heights (exact at
/// ordinary text sizes), and a label wraps onto a second line at large
/// text instead of being cut off.

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

Widget _button(
  ThirtyButton button, {
  required double width,
  double textScale = 1.0,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: Center(child: SizedBox(width: width, child: button)),
      ),
    ),
  );
}

/// The label's paragraph (found by its text: an [Icon] renders a
/// RichText of its own).
RenderParagraph _label(WidgetTester tester, String text, [Finder? button]) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(
        of: button ?? find.byType(ThirtyButton),
        matching: find.text(text),
      ),
    );

int _lineCount(RenderParagraph paragraph) => paragraph
    .getBoxesForSelection(
      TextSelection(
        baseOffset: 0,
        extentOffset: paragraph.text.toPlainText().length,
      ),
    )
    .map((box) => box.top)
    .toSet()
    .length;

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
    await _loadFont('Newsreader', ['assets/fonts/Newsreader[opsz,wght].ttf']);
  });

  group('100% text: exactly 48pt / 56pt, unchanged', () {
    for (final width in [320.0, 360.0]) {
      for (final size in ThirtyButtonSize.values) {
        for (final variant in ThirtyButtonVariant.values) {
          for (final trailing in [false, true]) {
            testWidgets('${width.toInt()}pt, ${size.name}, ${variant.name}, '
                'trailing icon: $trailing', (tester) async {
              await tester.pumpWidget(
                _button(
                  ThirtyButton(
                    label: 'Start Circle',
                    size: size,
                    variant: variant,
                    trailingIcon: trailing
                        ? Icons.arrow_forward_rounded
                        : null,
                    onPressed: () {},
                  ),
                  width: width - AppSpacing.page * 2,
                ),
              );
              expect(
                tester.getSize(find.byType(ThirtyButton)).height,
                size == ThirtyButtonSize.hero ? 56 : 48,
              );
              expect(_lineCount(_label(tester, 'Start Circle')), 1);
            });
          }
        }
      }
    }
  });

  group('200% text: wraps to two lines instead of truncating', () {
    // Labels at the widths their real call sites give them at 320pt (and
    // 360pt): You's Premium card, the Home CTA column, Circle history's
    // paired data controls, the Plan session pair.
    for (final (label, width320, width360) in [
      ('Upgrade to Premium', 224.0, 264.0),
      ('Become Premium', 224.0, 264.0),
      ('Manage subscription', 224.0, 264.0),
      ('Restore purchases', 224.0, 264.0),
      ("Begin today's Circle", 231.0, 265.0),
      ('Close Circle', 231.0, 265.0),
      ('Copy as text', 132.0, 152.0),
      ('Delete all', 132.0, 152.0),
      ('Standard', 132.0, 152.0),
      ('Lighter', 132.0, 152.0),
      ('Open Premium', 272.0, 312.0),
    ]) {
      for (final width in [width320, width360]) {
        testWidgets('"$label" at ${width.toInt()}pt', (tester) async {
          await tester.pumpWidget(
            _button(
              ThirtyButton(label: label, onPressed: () {}),
              width: width,
              textScale: 2.0,
            ),
          );
          final paragraph = _label(tester, label);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(_lineCount(paragraph), lessThanOrEqualTo(2));
          expect(
            tester.getSize(find.byType(ThirtyButton)).height,
            greaterThanOrEqualTo(48),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('a wrapped button keeps one semantics node with its full '
        'label, and loading keeps its size', (tester) async {
      await tester.pumpWidget(
        _button(
          ThirtyButton(label: 'Manage subscription', onPressed: () {}),
          width: 224,
          textScale: 2.0,
        ),
      );
      final idle = tester.getSize(find.byType(ThirtyButton));
      expect(_lineCount(_label(tester, 'Manage subscription')), 2);
      expect(
        tester.getSemantics(find.byType(ThirtyButton)).label,
        'Manage subscription',
      );

      await tester.pumpWidget(
        _button(
          ThirtyButton(
            label: 'Manage subscription',
            isLoading: true,
            onPressed: () {},
          ),
          width: 224,
          textScale: 2.0,
        ),
      );
      expect(tester.getSize(find.byType(ThirtyButton)), idle);
    });
  });

  group('Consumers at 200% text', () {
    testWidgets('Circle history data controls: the pair shares one height '
        'and neither label is cut off', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await CircleJournalRepository(prefs).recordShown(
        circleId: '2026-08-01',
        localDate: '2026-08-01',
        direction: Intention.moreEnergy,
        activityId: ActivityId.thirtyMinuteWalk,
        shownAt: DateTime(2026, 8, 1, 9),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(width: 272, child: JournalDataControls()),
                ),
              ),
            ),
          ),
        ),
      );

      final copy = find.widgetWithText(ThirtyButton, 'Copy as text');
      final delete = find.widgetWithText(ThirtyButton, 'Delete all');
      expect(tester.getSize(copy).height, tester.getSize(delete).height);
      expect(_label(tester, 'Copy as text', copy).didExceedMaxLines, isFalse);
      expect(_label(tester, 'Delete all', delete).didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });

    for (final width in [320.0, 360.0]) {
      testWidgets('${width.toInt()}pt: Home Start keeps its centered label '
          'and trailing arrow, uncut and unoverlapped', (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          recommendationDayKey: '2026-08-02',
          recommendationIntentionKey: 'moreEnergy',
          recommendationActivityIdKey: 'thirtyMinuteWalk',
        });
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              nowProvider.overrideWithValue(DateTime(2026, 8, 2)),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: const TextScaler.linear(2.0),
                  ),
                  child: const HomePage(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final start = find.widgetWithText(ThirtyButton, 'Start Circle');
        final label = tester.getRect(find.text('Start Circle'));
        final arrow = tester.getRect(find.byIcon(Icons.arrow_forward_rounded));
        final button = tester.getRect(start);
        expect(_label(tester, 'Start Circle', start).didExceedMaxLines, isFalse);
        expect(label.center.dx, closeTo(button.center.dx, 0.5));
        expect(label.overlaps(arrow), isFalse);
        expect(button.contains(arrow.center), isTrue);
        expect(tester.getSemantics(start).label, 'Start Circle');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
