import 'package:flutter_test/flutter_test.dart';

import 'report.dart';

/// Passes when at most [max] widgets your code created were rebuilt, or,
/// with [type], when widgets of that type were rebuilt at most [max] times.
///
/// ```dart
/// expect(report, rebuildsAtMost(3));
/// expect(report, rebuildsAtMost(1, type: PriceTag));
/// ```
Matcher rebuildsAtMost(int max, {Type? type}) => _RebuildMatcher(
  (n) => n <= max,
  type == null ? 'at most $max rebuilds of your widgets' : 'at most $max rebuilds of $type',
  type,
);

/// Passes when exactly [count] widgets your code created were rebuilt (or,
/// with [type], widgets of that type).
Matcher rebuildsExactly(int count, {Type? type}) => _RebuildMatcher(
  (n) => n == count,
  type == null ? 'exactly $count rebuilds of your widgets' : 'exactly $count rebuilds of $type',
  type,
);

/// Passes when no widget of [type] was rebuilt, e.g. an expensive chart
/// that should be isolated from a counter.
Matcher doesNotRebuild(Type type) => _RebuildMatcher((n) => n == 0, 'no rebuilds of $type', type);

class _RebuildMatcher extends Matcher {
  const _RebuildMatcher(this._test, this._description, this._type);

  final bool Function(int) _test;
  final String _description;
  final Type? _type;

  int _measure(RebuildReport r) => _type == null ? r.total : r.count(_type);

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! RebuildReport) return false;
    return _test(_measure(item));
  }

  @override
  Description describe(Description description) => description.add(_description);

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! RebuildReport) {
      return mismatchDescription.add('is not a RebuildReport (did you forget to await tester.measureRebuilds?)');
    }
    final n = _measure(item);
    final what = _type == null ? 'your widgets rebuilt $n times' : '$_type rebuilt $n times';
    return mismatchDescription.add(what); // the report itself is printed as "Actual"
  }
}
