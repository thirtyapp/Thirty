import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';

void main() {
  group('AppTypography.editorialDisplay', () {
    test('is Newsreader Regular at the approved size/height/spacing', () {
      final style = AppTypography.editorialDisplay(AppColors.light);

      expect(style.fontFamily, 'Newsreader');
      expect(style.fontWeight, FontWeight.w400);
      expect(style.fontSize, 28);
      expect(style.height, 1.21);
      expect(style.letterSpacing, 0);
    });

    test('follows textPrimary per palette, not a hardcoded color', () {
      expect(
        AppTypography.editorialDisplay(AppColors.light).color,
        AppColors.light.textPrimary,
      );
      expect(
        AppTypography.editorialDisplay(AppColors.dark).color,
        AppColors.dark.textPrimary,
      );
    });
  });
}
