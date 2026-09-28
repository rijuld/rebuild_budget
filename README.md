<div align="center">

# 🎯 rebuild_budget

**Rebuild budgets for Flutter widget tests.**

Measure exactly which widgets an interaction rebuilds, give it a budget, and fail CI
with a readable report the day someone's `setState` starts rebuilding half the screen.

![license: MIT](https://img.shields.io/badge/license-MIT-blue)
![flutter: 3.32+](https://img.shields.io/badge/flutter-3.32%2B-02569B)
![dependencies: flutter_test only](https://img.shields.io/badge/deps-flutter__test%20only-brightgreen)

```dart
final report = await tester.measureRebuilds(() => tester.tap(find.byIcon(Icons.add)));
expect(report, rebuildsAtMost(4));
expect(report, doesNotRebuild(PriceChart));
```

</div>

---

## Why

Unnecessary rebuilds are the most common Flutter performance bug, and the most
invisible. The app still works. It just gets a little slower with every `setState`
that moved up a level, every `const` someone deleted, and every provider that now
listens to the whole model. DevTools' rebuild tracker can show you, if you happen to
look, in a running app, on the right screen.

`rebuild_budget` turns that into a **test**. You say "tapping + may rebuild at most 4 of
my widgets, and never the chart", and CI keeps it true. That matters more when your
code is increasingly written by assistants that reach for `setState` at the top of the
tree.

## What a failure looks like

This is real output from a test whose screen calls `setState` at the top of the page:

```text
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: at most 4 rebuilds of your widgets
  Actual: RebuildReport:<REBUILD REPORT · tap +
          1 frame · 7 rebuilds of widgets your code created
          ──────────────────────────────────────────────────────────
            WIDGET                                    REBUILDS  FRAMES
            WastefulPage                                     1  1
            MaterialApp under WastefulPage                   1  1
            Scaffold under MaterialApp                       1  1
            PriceChart under Scaffold                        1  1
            CountLabel under Scaffold                        1  1
            Text under CountLabel                            1  1
            IconButton under Scaffold                        1  1
          ──────────────────────────────────────────────────────────
            + 151 framework-internal rebuilds (not budgeted)
          >
   Which: your widgets rebuilt 7 times
```

With state moved into the counter and the chart made `const`, the same tap rebuilds 4
widgets (`_Counter`, `CountLabel`, its `Text` and the `IconButton`) and never the
chart. Both versions are in the [example app](example/lib/main.dart), which shows a
live "chart built N times" counter so you can *see* the waste.

## Install

```yaml
dev_dependencies:
  rebuild_budget:
    git: https://github.com/rijuld/rebuild_budget
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebuild_budget/rebuild_budget.dart';

void main() {
  testWidgets('adding a cup never rebuilds the chart', (tester) async {
    await tester.pumpWidget(const MyApp());

    final report = await tester.measureRebuilds(
      () => tester.tap(find.byIcon(Icons.add)),
      label: 'add a cup', // shown in the report header
    );

    expect(report, rebuildsAtMost(4));                   // total, your widgets
    expect(report, doesNotRebuild(PriceChart));          // one type, never
    expect(report, rebuildsAtMost(1, type: CupCounter)); // one type, capped
  });
}
```

### Matchers

| Matcher | Passes when |
| --- | --- |
| `rebuildsAtMost(n)` | widgets your code created were rebuilt at most `n` times |
| `rebuildsAtMost(n, type: T)` | widgets of type `T` were rebuilt at most `n` times |
| `rebuildsExactly(n, {type})` | exactly `n` (good for pinning a known-good number) |
| `doesNotRebuild(T)` | widgets of type `T` were not rebuilt at all |

### The report

`measureRebuilds` returns a `RebuildReport` you can also query directly:

```dart
report.total              // rebuilds of widgets your code created (what budgets count)
report.of<PriceChart>()   // rebuilds of one type
report.byWidget           // {'PriceChart under Scaffold': 1, ...}
report.perFrame           // [3, 3, 3] for a three-frame animation
report.frameworkRebuilds  // Flutter's internal widgets, reported but never budgeted
report.mounts             // elements built for the first time, never counted as rebuilds
print(report);            // the table above
```

### Animations

The helper owns the pump. By default it pumps once if a frame is pending, so a bare
`tester.tap` is enough. Pass `settle: true` to run `pumpAndSettle`. Every frame is
recorded separately, so an animation shows up as a breakdown instead of a surprising
total:

```text
REBUILD REPORT
3 frames · 9 rebuilds of widgets your code created
──────────────────────────────────────────────────────────
  WIDGET                                    REBUILDS  FRAMES
  AnimatedBuilder under GestureDetector            3  1,2,3
  CountLabel under AnimatedBuilder                 3  1,2,3
  Text under CountLabel                            3  1,2,3
──────────────────────────────────────────────────────────
  per frame: 3 · 3 · 3
  + 21 framework-internal rebuilds (not budgeted)
```

## How it works

- **Flutter's own hook.** It installs `debugOnRebuildDirtyWidget`, the same callback
  DevTools uses, for the duration of your action, and restores whatever was there
  before.
- **"Your" widgets are the widgets your code constructed.** Under `flutter test`,
  widget creation locations are tracked, and `debugIsWidgetLocalCreation` says whether
  a widget instance was created outside `package:flutter`. A `Text` you wrote in a
  `build` method counts; the dozens of widgets `Scaffold` builds internally don't.
  That's why budgets don't break when you upgrade Flutter.
- **Rebuilds vs first builds.** Flutter's `builtOnce` flag is only maintained when
  `debugPrintRebuildDirtyWidgets` is on, so rebuild_budget snapshots the element tree
  before your action instead. Any element it didn't see before is being mounted, and
  that's reported separately rather than charged to your budget.
- **Per-frame buckets** come from a post-frame callback that re-arms itself each frame.

### Limitations

- Debug mode only (Flutter only reports rebuilds there), which is what `flutter test`
  runs by default. It also needs widget creation tracking, which is on by default. With
  `--no-track-widget-creation` it throws instead of passing every budget silently.
- Tested on Flutter 3.47 / Dart 3.13. The pubspec allows 3.32+, and CI will say whether
  that holds.
- It counts **builds**, not layout or paint. A widget that rebuilds cheaply but
  relayouts expensively won't show up; `RepaintBoundary` issues need DevTools.
- Widgets created by *third-party packages* count as "yours", because they aren't
  created by `package:flutter`. Budget them by type if they're noisy.

## Prior art

- [DevTools' rebuild stats](https://docs.flutter.dev/tools/devtools/performance)
  show the same data interactively. rebuild_budget makes it assertable in CI.
- Golden tests catch *visual* regressions. This catches *performance-shape* regressions
  that look identical on screen.

## Contributing

Issues and PRs are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). One note: the Flutter
tool currently breaks on project paths containing an apostrophe (`'`), so clone into a
path without one.

### Roadmap

Good first issues are marked 🌱.

- 🌱 `rebuildsAtMost` per frame (`maxPerFrame:`) for animations
- 🌱 A JSON dump of reports for tracking budgets over time
- A **rebuild heatmap**: a golden image with each widget tinted by how often it rebuilt
- `expectRebuildBudgets` driven by a YAML file of flows and budgets
- Creation file:line for each rebuilt widget in the report

## License

MIT. See [LICENSE](LICENSE).
