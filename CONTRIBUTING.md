# Contributing to rebuild_budget

Thanks for helping keep Flutter apps snappy. 🎯

## Setup

```sh
flutter pub get
flutter test                  # the package
cd example && flutter test    # the example app's budget tests
flutter analyze && dart format --set-exit-if-changed .
```

> The Flutter tool currently fails on project paths that contain an apostrophe
> (it embeds the path in a single-quoted Dart string). Clone somewhere without one.

## Codebase tour

| File | What it does |
| --- | --- |
| `lib/src/measure.dart` | `tester.measureRebuilds`: installs `debugOnRebuildDirtyWidget`, snapshots the element tree, buckets by frame, owns the pump. |
| `lib/src/report.dart` | `Rebuild` and `RebuildReport`: the data and the printed table. |
| `lib/src/matchers.dart` | `rebuildsAtMost`, `rebuildsExactly`, `doesNotRebuild`. |
| `test/fixtures.dart` | Small screens with known rebuild shapes (wasteful, fixed, toggle, animation). |

## Rules of thumb

- **Tests assert exact counts** on the fixtures. If a Flutter upgrade changes a count
  for *your* widgets, that's a real behaviour change worth understanding. If it changes
  framework counts, it shouldn't matter, because those are never budgeted.
- Always restore `debugOnRebuildDirtyWidget` (in a `finally`).
- Keep the only dependency `flutter_test`.
