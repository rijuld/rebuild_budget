/// Rebuild budgets for Flutter widget tests.
///
/// ```dart
/// testWidgets('tapping + only rebuilds the counter', (tester) async {
///   await tester.pumpWidget(const MyApp());
///   final report = await tester.measureRebuilds(() => tester.tap(find.byIcon(Icons.add)));
///   expect(report, rebuildsAtMost(2));
///   expect(report, doesNotRebuild(PriceChart));
/// });
/// ```
library;

export 'src/matchers.dart' show doesNotRebuild, rebuildsAtMost, rebuildsExactly;
export 'src/measure.dart' show RebuildBudgetTester;
export 'src/report.dart' show Rebuild, RebuildReport;
