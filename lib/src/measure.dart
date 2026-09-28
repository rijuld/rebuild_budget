import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'report.dart';

/// Rebuild measurement for widget tests.
extension RebuildBudgetTester on WidgetTester {
  /// Runs [action] and records every widget rebuild it causes.
  ///
  /// The helper owns the pump: after [action] completes it pumps once if a
  /// frame is still scheduled (so a bare `tester.tap` is enough), or runs
  /// `pumpAndSettle` when [settle] is true. Each frame is recorded separately,
  /// so animations show up as a per-frame breakdown rather than a mystery total.
  ///
  /// ```dart
  /// final report = await tester.measureRebuilds(() => tester.tap(find.byIcon(Icons.add)));
  /// expect(report, rebuildsAtMost(2));
  /// expect(report, doesNotRebuild(PriceChart));
  /// ```
  Future<RebuildReport> measureRebuilds(FutureOr<void> Function() action, {bool settle = false, String? label}) async {
    if (!kDebugMode) {
      throw StateError('measureRebuilds needs a debug build; Flutter only reports rebuilds in debug mode.');
    }
    if (!WidgetInspectorService.instance.isWidgetCreationTracked()) {
      // Without creation locations no widget looks like "yours", every total
      // would be 0 and every budget would pass. Refuse instead.
      throw StateError(
        'measureRebuilds needs widget creation tracking to tell your widgets from Flutter\'s. '
        'It is on by default in `flutter test`; don\'t pass --no-track-widget-creation.',
      );
    }

    // Elements that exist now can only *re*build. Anything built later that
    // we haven't seen is being mounted for the first time. (The builtOnce flag
    // Flutter passes to the callback is only maintained when
    // debugPrintRebuildDirtyWidgets is on, so we can't rely on it.)
    final seen = Expando<bool>('rebuild_budget.seen');
    void markExisting(Element e) {
      seen[e] = true;
      e.visitChildren(markExisting);
    }

    final root = binding.rootElement;
    if (root != null) markExisting(root);

    final events = <Rebuild>[];
    var frame = 1;
    var measuring = true;
    void onFrameEnd(Duration _) {
      if (!measuring) return;
      frame++;
      SchedulerBinding.instance.addPostFrameCallback(onFrameEnd);
    }

    SchedulerBinding.instance.addPostFrameCallback(onFrameEnd);

    final previous = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (Element element, bool builtOnce) {
      previous?.call(element, builtOnce);
      final firstBuild = seen[element] == null;
      seen[element] = true;
      final yours = debugIsWidgetLocalCreation(element.widget);
      events.add(
        Rebuild(
          widgetType: element.widget.runtimeType,
          frame: frame,
          yours: yours,
          firstBuild: firstBuild,
          parent: yours ? _nearestLocalAncestor(element) : null,
        ),
      );
    };

    try {
      await action();
      if (settle) {
        await pumpAndSettle();
      } else if (binding.hasScheduledFrame) {
        await pump();
      }
    } finally {
      debugOnRebuildDirtyWidget = previous;
      measuring = false;
    }

    // `frame` is advanced after every drawn frame, so frame - 1 frames were drawn.
    return RebuildReport(label: label, frames: frame - 1, events: events);
  }
}

Type? _nearestLocalAncestor(Element element) {
  Type? found;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is! StatelessWidget && widget is! StatefulWidget) return true;
    if (debugIsWidgetLocalCreation(widget) && widget.runtimeType != element.widget.runtimeType) {
      found = widget.runtimeType;
      return false;
    }
    return true;
  });
  return found;
}
