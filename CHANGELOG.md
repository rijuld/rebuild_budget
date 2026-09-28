## 0.1.0

- `tester.measureRebuilds(action, {settle, label})` records every widget rebuild an
  interaction causes, per frame, separating your widgets from Flutter's internals and
  rebuilds from first builds.
- Matchers: `rebuildsAtMost`, `rebuildsExactly`, `doesNotRebuild`, with the full report
  as the failure explanation.
