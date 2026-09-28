/// One widget rebuild observed while measuring.
class Rebuild {
  /// Creates a record of one rebuild.
  const Rebuild({
    required this.widgetType,
    required this.frame,
    required this.yours,
    required this.firstBuild,
    this.parent,
  });

  /// The widget's runtime type, e.g. `PriceTag` or `Consumer<Cart>`.
  final Type widgetType;

  /// 1-based index of the frame this build happened in.
  final int frame;

  /// True when the widget was *created by your code* (its constructor was
  /// called outside `package:flutter`). Only these count towards budgets, so
  /// budgets don't break when Flutter's internals change.
  final bool yours;

  /// True when the element was built for the first time (newly mounted).
  /// First builds are reported but never count as rebuilds.
  final bool firstBuild;

  /// The nearest ancestor widget created by your code, for context
  /// ("Text under PriceTag").
  final Type? parent;

  /// `PriceTag`, or `Text under PriceTag` when a parent is known.
  String get label => parent == null || parent == widgetType ? '$widgetType' : '$widgetType under $parent';
}

/// What an interaction rebuilt. Get one from `tester.measureRebuilds`.
class RebuildReport {
  /// Creates a report; you normally get one from `tester.measureRebuilds`.
  RebuildReport({this.label, required this.frames, required List<Rebuild> events})
    : _events = List<Rebuild>.unmodifiable(events);

  /// Optional description shown in the report header.
  final String? label;

  /// Number of frames pumped while measuring.
  final int frames;

  final List<Rebuild> _events;

  /// Every build seen, including first builds and framework-internal widgets.
  List<Rebuild> get events => _events;

  /// Rebuilds of widgets your code created. This is what budgets count.
  List<Rebuild> get rebuilds => _events.where((e) => e.yours && !e.firstBuild).toList();

  /// Rebuilds of widgets created inside Flutter itself (not budgeted).
  List<Rebuild> get frameworkRebuilds => _events.where((e) => !e.yours && !e.firstBuild).toList();

  /// Elements built for the first time (newly mounted), yours or not.
  List<Rebuild> get mounts => _events.where((e) => e.firstBuild).toList();

  /// Total rebuilds of widgets your code created.
  int get total => rebuilds.length;

  /// Rebuilds of widgets of exactly type [T], yours or framework-created.
  int of<T>() => count(T);

  /// Rebuilds of widgets whose runtime type is [type], yours or framework-created.
  int count(Type type) => _events.where((e) => !e.firstBuild && e.widgetType == type).length;

  /// Your rebuilds grouped by [Rebuild.label], most first.
  Map<String, int> get byWidget {
    final counts = <String, int>{};
    for (final r in rebuilds) {
      counts[r.label] = (counts[r.label] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map<String, int>.fromEntries(sorted);
  }

  /// Rebuilds of your widgets in each frame (index 0 is frame 1).
  List<int> get perFrame => [for (var f = 1; f <= frames; f++) rebuilds.where((r) => r.frame == f).length];

  @override
  String toString() {
    const width = 58;
    final out = StringBuffer();
    final rule = '─' * width;
    final title = 'REBUILD REPORT${label == null ? '' : ' · $label'}';
    out
      ..writeln(title)
      ..writeln(
        '$frames frame${frames == 1 ? '' : 's'} · '
        '$total rebuild${total == 1 ? '' : 's'} of widgets your code created',
      )
      ..writeln(rule);
    final rows = byWidget;
    if (rows.isEmpty) {
      out.writeln('  (none of your widgets rebuilt)');
    } else {
      out.writeln('  ${'WIDGET'.padRight(40)}${'REBUILDS'.padLeft(10)}  FRAMES');
      for (final entry in rows.entries) {
        final frameList = rebuilds.where((r) => r.label == entry.key).map((r) => r.frame).toSet().toList()..sort();
        final name = entry.key.length > 40 ? '${entry.key.substring(0, 39)}…' : entry.key;
        out.writeln('  ${name.padRight(40)}${'${entry.value}'.padLeft(10)}  ${_ranges(frameList)}');
      }
    }
    out.writeln(rule);
    if (frames > 1) {
      out.writeln('  per frame: ${perFrame.join(' · ')}');
    }
    final fw = frameworkRebuilds.length;
    out.writeln('  + $fw framework-internal rebuild${fw == 1 ? '' : 's'} (not budgeted)');
    final m = mounts.length;
    if (m > 0) {
      out.writeln('  + $m element${m == 1 ? '' : 's'} built for the first time (not budgeted)');
    }
    return out.toString();
  }

  static String _ranges(List<int> frames) {
    if (frames.length <= 4) return frames.join(',');
    return '${frames.first}–${frames.last}';
  }
}
