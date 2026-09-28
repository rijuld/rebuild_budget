import 'package:flutter/material.dart';

/// A stand-in for something expensive to build: a chart, a map, a long list.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: 100, child: Placeholder());
}

class CountLabel extends StatelessWidget {
  const CountLabel(this.count, {super.key});
  final int count;

  @override
  Widget build(BuildContext context) => Text('Count: $count');
}

/// The classic mistake: setState at the top of the page rebuilds everything.
class WastefulPage extends StatefulWidget {
  const WastefulPage({super.key});

  @override
  State<WastefulPage> createState() => _WastefulPageState();
}

class _WastefulPageState extends State<WastefulPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            PriceChart(), // ignore: prefer_const_constructors
            CountLabel(_count),
            IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _count++)),
          ],
        ),
      ),
    );
  }
}

/// The fix: state lives next to the thing that changes; the chart is const.
class FixedPage extends StatelessWidget {
  const FixedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Column(children: [PriceChart(), _Counter()])),
    );
  }
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CountLabel(_count),
        IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _count++)),
      ],
    );
  }
}

/// Toggling mounts a new subtree: first builds must not count as rebuilds.
class TogglePage extends StatefulWidget {
  const TogglePage({super.key});

  @override
  State<TogglePage> createState() => _TogglePageState();
}

class _TogglePageState extends State<TogglePage> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TextButton(onPressed: () => setState(() => _open = !_open), child: const Text('toggle')),
            if (_open) const PriceChart(),
          ],
        ),
      ),
    );
  }
}

/// Rebuilds on every animation frame.
class Pulse extends StatefulWidget {
  const Pulse({super.key});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GestureDetector(
        onTap: () => _c.forward(from: 0),
        child: AnimatedBuilder(animation: _c, builder: (context, _) => CountLabel((_c.value * 10).round())),
      ),
    );
  }
}
