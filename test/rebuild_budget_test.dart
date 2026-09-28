import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebuild_budget/rebuild_budget.dart';

import 'fixtures.dart';

void main() {
  group('measureRebuilds', () {
    testWidgets('a top-level setState rebuilds the whole page', (tester) async {
      await tester.pumpWidget(const WastefulPage());
      final report = await tester.measureRebuilds(() => tester.tap(find.byIcon(Icons.add)));

      expect(report.frames, 1);
      expect(report.total, 7);
      expect(report.of<PriceChart>(), 1);
      expect(report.of<CountLabel>(), 1);
      expect(report.byWidget.keys, contains('PriceChart under Scaffold'));
      expect(report.frameworkRebuilds, isNotEmpty);
      expect(report.mounts, isEmpty);
    });

    testWidgets('isolated state rebuilds only the counter', (tester) async {
      await tester.pumpWidget(const FixedPage());
      final report = await tester.measureRebuilds(() => tester.tap(find.byIcon(Icons.add)));

      expect(report.total, 4);
      expect(report.of<PriceChart>(), 0);
      expect(report.of<CountLabel>(), 1);
      expect(find.text('Count: 1'), findsOneWidget, reason: 'the helper pumped the frame');
    });

    testWidgets('newly mounted widgets are first builds, not rebuilds', (tester) async {
      await tester.pumpWidget(const TogglePage());
      final report = await tester.measureRebuilds(() => tester.tap(find.text('toggle')));

      expect(report.of<PriceChart>(), 0);
      expect(report.mounts.map((m) => m.widgetType), contains(PriceChart));
      expect(report.total, 4);
    });

    testWidgets('settle records every animation frame separately', (tester) async {
      await tester.pumpWidget(const Pulse());
      final report = await tester.measureRebuilds(() => tester.tap(find.byType(CountLabel)), settle: true);

      expect(report.frames, 3);
      expect(report.perFrame, [3, 3, 3]);
      expect(report.of<CountLabel>(), 3);
    });

    testWidgets('an action that changes nothing reports nothing', (tester) async {
      await tester.pumpWidget(const FixedPage());
      final report = await tester.measureRebuilds(() {});
      expect(report.total, 0);
      expect(report.toString(), contains('(none of your widgets rebuilt)'));
    });

    testWidgets('restores any existing rebuild callback', (tester) async {
      final outer = <Type>[];
      void callback(Element e, bool _) => outer.add(e.widget.runtimeType);
      debugOnRebuildDirtyWidget = callback;
      try {
        await tester.pumpWidget(const WastefulPage());
        await tester.measureRebuilds(() => tester.tap(find.byIcon(Icons.add)));
        expect(debugOnRebuildDirtyWidget, same(callback));
        expect(outer, contains(PriceChart), reason: 'the previous callback still sees events');
      } finally {
        debugOnRebuildDirtyWidget = null;
      }
    });
  });

  group('matchers', () {
    testWidgets('pass and fail with the report as the explanation', (tester) async {
      await tester.pumpWidget(const WastefulPage());
      final report = await tester.measureRebuilds(() => tester.tap(find.byIcon(Icons.add)), label: 'tap +');

      expect(report, rebuildsAtMost(7));
      expect(report, rebuildsExactly(7));
      expect(report, rebuildsExactly(1, type: PriceChart));
      expect(report, isNot(doesNotRebuild(PriceChart)));

      final matcher = rebuildsAtMost(2);
      expect(matcher.matches(report, {}), isFalse);
      final mismatch = matcher.describeMismatch(report, StringDescription(), {}, false).toString();
      expect(mismatch, 'your widgets rebuilt 7 times');
      expect(report.toString(), contains('REBUILD REPORT · tap +'));
      expect(report.toString(), contains('PriceChart under Scaffold'));
      expect(matcher.describe(StringDescription()).toString(), 'at most 2 rebuilds of your widgets');
    });

    testWidgets('the fixed page stays within budget', (tester) async {
      await tester.pumpWidget(const FixedPage());
      final report = await tester.measureRebuilds(() => tester.tap(find.byIcon(Icons.add)));
      expect(report, rebuildsAtMost(4));
      expect(report, doesNotRebuild(PriceChart));
    });

    test('non-reports explain themselves', () {
      final text = rebuildsAtMost(1).describeMismatch(42, StringDescription(), {}, false).toString();
      expect(text, contains('did you forget to await'));
    });
  });
}
