import 'package:flutter_test/flutter_test.dart';

import 'package:thirty/core/theme/design_tokens.dart';

void main() {
  test('Phase A2 keeps the existing semantic spacing values unchanged', () {
    expect(AppSpacing.page, 24);
    expect(AppSpacing.section, 32);
    expect(AppSpacing.card, 16);
  });

  test('featuredCard is the opt-in roomier card padding', () {
    expect(AppSpacing.featuredCard, 24);
    expect(AppSpacing.featuredCard, greaterThan(AppSpacing.card));
  });
}
