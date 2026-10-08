import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';
import 'package:thirty/core/widgets/thirty_confirm_dialog.dart';

/// Phase C5 — THIRTY's confirmation dialog with the app's real fonts: at
/// 320 / 360pt and 200% text, light and dark, every audited dialog's title,
/// body and both actions are fully reachable, nothing is cut off or broken
/// mid-word, stacked actions keep 8pt between them and every action keeps
/// a 48pt target. At 100% text it lays out exactly like the pre-C5 dialog.

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// The three audited dialogs, copy verbatim from their call sites.
const _dialogs = [
  ThirtyConfirmDialog(
    title: 'Delete your Circle history?',
    body:
        'This permanently deletes every recorded Circle on this device. '
        'It cannot be undone, and nothing is stored anywhere else to '
        'restore it from.',
    cancelLabel: 'Keep my history',
    confirmLabel: 'Delete permanently',
    destructive: true,
  ),
  ThirtyConfirmDialog(
    title: "Close today's Circle?",
    body: "You won't be able to reopen it until tomorrow.",
    cancelLabel: 'Keep Circle open',
    confirmLabel: 'Close Circle',
    destructive: true,
  ),
  ThirtyConfirmDialog(
    title: 'Allow Alarms & reminders',
    body:
        'Android needs "Alarms & reminders" access so THIRTY can '
        'deliver your Circle reminder at the time you choose.',
    cancelLabel: 'Not now',
    confirmLabel: 'Continue',
  ),
];

/// The pre-C5 presentation, for the unchanged-at-100% comparison.
Widget _preC5(ThirtyConfirmDialog d, AppColors colors) => AlertDialog(
  title: Text(d.title),
  content: Text(d.body),
  actions: [
    TextButton(onPressed: () {}, child: Text(d.cancelLabel)),
    TextButton(
      onPressed: () {},
      style: d.destructive
          ? TextButton.styleFrom(foregroundColor: colors.errorText)
          : null,
      child: Text(d.confirmLabel),
    ),
  ],
);

/// Pumps a launcher, opens [builder]'s dialog, and returns a getter for the
/// value the dialog popped with.
Future<bool? Function()> _open(
  WidgetTester tester,
  Widget Function(AppColors colors) builder, {
  double width = 360,
  double height = 740,
  double textScale = 1,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      // A fresh app (and Navigator) per launch, so a previous dialog is
      // never still open.
      key: UniqueKey(),
      theme: theme ?? AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      builder(Theme.of(context).extension<AppColors>()!),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byType(AlertDialog), matching: find.text(text)),
    );

/// The paragraph laid out again without any height limit.
TextPainter _unclipped(RenderParagraph p) => TextPainter(
  text: p.text,
  textDirection: TextDirection.ltr,
  textScaler: p.textScaler,
)..layout(maxWidth: p.constraints.maxWidth);

/// Offsets where a line starts inside a word.
List<int> _midWordBreaks(RenderParagraph p) {
  final painter = _unclipped(p);
  final text = p.text.toPlainText();
  return [
    for (var i = 1; i < text.length; i++)
      if (painter.getLineBoundary(TextPosition(offset: i)).start == i &&
          text[i - 1].trim().isNotEmpty &&
          text[i].trim().isNotEmpty)
        i,
  ];
}

Rect _button(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
);

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
  });

  group('200% text: fully reachable, nothing cut or broken mid-word', () {
    for (final (width, height) in [(320.0, 640.0), (360.0, 740.0)]) {
      for (final (themeName, theme) in [
        ('light', AppTheme.light),
        ('dark', AppTheme.dark),
      ]) {
        for (final dialog in _dialogs) {
          testWidgets('${width.toInt()}pt, $themeName: "${dialog.title}"', (
            tester,
          ) async {
            await _open(
              tester,
              (_) => dialog,
              width: width,
              height: height,
              textScale: 2,
              theme: theme,
            );
            expect(tester.takeException(), isNull);

            // 16pt side inset at large text.
            final surface = tester.getRect(
              find
                  .descendant(
                    of: find.byType(AlertDialog),
                    matching: find.byType(Material),
                  )
                  .first,
            );
            expect(surface.left, AppSpacing.m);
            expect(surface.right, width - AppSpacing.m);

            for (final text in [
              dialog.title,
              dialog.body,
              dialog.cancelLabel,
              dialog.confirmLabel,
            ]) {
              final p = _paragraph(tester, text);
              expect(p.didExceedMaxLines, isFalse, reason: text);
              expect(
                p.size.height,
                greaterThanOrEqualTo(_unclipped(p).height - 0.5),
                reason: '"$text" is laid out in full',
              );
              expect(_midWordBreaks(p), isEmpty, reason: text);
            }

            // Title and body scroll; the end of the body can be reached.
            final scrollable = find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Scrollable),
            );
            expect(scrollable, findsOneWidget);
            await tester.drag(scrollable, const Offset(0, -2000));
            await tester.pumpAndSettle();
            final viewport = tester.getRect(scrollable);
            final body = tester.getRect(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.text(dialog.body),
              ),
            );
            expect(body.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));

            // Both actions on screen, tappable, ≥ 48pt, 8pt apart if stacked.
            final cancel = _button(tester, dialog.cancelLabel);
            final confirm = _button(tester, dialog.confirmLabel);
            for (final (label, rect) in [
              (dialog.cancelLabel, cancel),
              (dialog.confirmLabel, confirm),
            ]) {
              expect(rect.height, greaterThanOrEqualTo(48), reason: label);
              expect(rect.width, greaterThanOrEqualTo(48), reason: label);
              expect(rect.bottom, lessThanOrEqualTo(height), reason: label);
              expect(
                find.text(label).hitTestable(),
                findsOneWidget,
                reason: label,
              );
            }
            if (confirm.top >= cancel.bottom) {
              expect(confirm.top - cancel.bottom, AppSpacing.s);
            }
          });
        }
      }
    }
  });

  group('100% text: laid out exactly as before C5', () {
    for (final (themeName, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      for (final dialog in _dialogs) {
        testWidgets('360pt, $themeName: "${dialog.title}"', (tester) async {
          Map<String, Rect> geometry() => {
            for (final text in [
              dialog.title,
              dialog.body,
              dialog.cancelLabel,
              dialog.confirmLabel,
            ])
              text: tester.getRect(
                find.descendant(
                  of: find.byType(AlertDialog),
                  matching: find.text(text),
                ),
              ),
            'surface': tester.getRect(
              find
                  .descendant(
                    of: find.byType(AlertDialog),
                    matching: find.byType(Material),
                  )
                  .first,
            ),
          };

          await _open(tester, (colors) => _preC5(dialog, colors), theme: theme);
          final before = geometry();
          await _open(tester, (_) => dialog, theme: theme);
          final after = geometry();

          expect(after, before);
        });
      }
    }
  });

  group('behaviour', () {
    const dialog = ThirtyConfirmDialog(
      title: 'Title',
      body: 'Body',
      cancelLabel: 'Keep',
      confirmLabel: 'Go',
      destructive: true,
    );

    testWidgets('cancel pops false', (tester) async {
      final result = await _open(tester, (_) => dialog);
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(result(), isFalse);
    });

    testWidgets('confirm pops true', (tester) async {
      final result = await _open(tester, (_) => dialog);
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(result(), isTrue);
    });

    testWidgets('a barrier tap pops null', (tester) async {
      final result = await _open(tester, (_) => dialog);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(result(), isNull);
    });

    testWidgets('destructive confirm uses errorText; plain confirm does not', (
      tester,
    ) async {
      Color? confirmColor(WidgetTester tester, String label) => tester
          .widget<TextButton>(find.widgetWithText(TextButton, label))
          .style
          ?.foregroundColor
          ?.resolve({});

      await _open(tester, (_) => dialog);
      expect(confirmColor(tester, 'Go'), AppColors.light.errorText);

      await _open(
        tester,
        (_) => const ThirtyConfirmDialog(
          title: 'Title',
          body: 'Body',
          cancelLabel: 'Keep',
          confirmLabel: 'Go',
        ),
      );
      expect(confirmColor(tester, 'Go'), isNull);
    });
  });
}
