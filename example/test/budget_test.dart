import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebuild_budget/rebuild_budget.dart';
import 'package:rebuild_budget_example/main.dart';

void main() {
  testWidgets('adding a cup on the fixed screen never rebuilds the chart', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: FixedScreen())));
    final report = await tester.measureRebuilds(() => tester.tap(find.byIcon(Icons.add)), label: 'add a cup');

    expect(report, doesNotRebuild(PriceChart));
    expect(report, rebuildsAtMost(4));
  });

  testWidgets('the wasteful screen rebuilds the chart (this is the bug)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: WastefulScreen())));
    final report = await tester.measureRebuilds(() => tester.tap(find.byIcon(Icons.add)), label: 'add a cup');

    expect(report, rebuildsExactly(1, type: PriceChart));
    expect(report, isNot(rebuildsAtMost(4)));
  });
}
