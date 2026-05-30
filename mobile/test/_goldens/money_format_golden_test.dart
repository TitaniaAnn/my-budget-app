// Proof-of-concept golden test. Audit 2026-05-26 T2.
//
// One concrete example that anchors the pattern; the audit
// called out four candidates (dashboard cards, net-worth chart,
// budget progress bars, monthly-report PDF) and additional
// goldens follow the same structure.
//
// Workflow for adding / updating goldens:
//   1. Run `flutter test --update-goldens test/_goldens/`
//      from the mobile/ directory. The first run generates the
//      reference PNGs under test/_goldens/<test_name>/<file>.png.
//   2. Eyeball the PNG. If it matches what the UI should look
//      like, commit it alongside the test.
//   3. On every subsequent `flutter test` run, the rendered
//      pixels are compared to the committed PNG. Any drift
//      (font kerning, color tweak, layout shift) fails the
//      test with a diff PNG written next to the original.
//
// Platform note: goldens are host-sensitive (font anti-aliasing
// differs across Linux / macOS / Windows). The reference PNGs
// committed here were generated on the dev's host; CI golden
// runs should be platform-pinned (commonly Linux). For now we
// keep the proof-of-concept narrow: a small text widget with
// the project's currency formatter, no images, no charts. The
// pixel diff over a handful of glyphs has the lowest cross-
// platform sensitivity.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/utils/money.dart';

/// Tiny stand-alone widget the goldens target. Pure rendering —
/// no providers, no theme extensions, no platform channels.
/// Extracted so the golden's PNG is self-contained and a future
/// refactor of any application widget doesn't move this pixel.
class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.cents, required this.currency});
  final int cents;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              formatCurrency(cents, currency: currency),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('formatCurrency USD positive — golden', (tester) async {
    await tester.pumpWidget(
      const _CurrencyChip(cents: 123456, currency: 'USD'),
    );
    await expectLater(
      find.byType(_CurrencyChip),
      matchesGoldenFile('goldens/currency_usd_positive.png'),
    );
  });

  testWidgets('formatCurrency USD negative — golden', (tester) async {
    await tester.pumpWidget(
      const _CurrencyChip(cents: -5042, currency: 'USD'),
    );
    await expectLater(
      find.byType(_CurrencyChip),
      matchesGoldenFile('goldens/currency_usd_negative.png'),
    );
  });

  testWidgets('formatCurrency EUR — golden', (tester) async {
    await tester.pumpWidget(
      const _CurrencyChip(cents: 1099, currency: 'EUR'),
    );
    await expectLater(
      find.byType(_CurrencyChip),
      matchesGoldenFile('goldens/currency_eur.png'),
    );
  });
}
