import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() => runApp(const DemoApp());

/// Two versions of the same screen. Tap + on each and watch the chart's
/// build counter: the wasteful one rebuilds the chart on every tap.
class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rebuild_budget demo',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: TabBar(
            tabs: [
              Tab(text: 'Wasteful'),
              Tab(text: 'Fixed'),
            ],
          ),
          body: TabBarView(children: [WastefulScreen(), FixedScreen()]),
        ),
      ),
    );
  }
}

/// setState at the top of the screen: every tap rebuilds the chart too.
class WastefulScreen extends StatefulWidget {
  const WastefulScreen({super.key});

  @override
  State<WastefulScreen> createState() => _WastefulScreenState();
}

class _WastefulScreenState extends State<WastefulScreen> {
  int _cups = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PriceChart(), // ignore: prefer_const_constructors
        CupCounter(cups: _cups, onAdd: () => setState(() => _cups++)),
      ],
    );
  }
}

/// The fix: the counter owns its state, and the chart is const.
class FixedScreen extends StatelessWidget {
  const FixedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [PriceChart(), StatefulCupCounter()]);
  }
}

class StatefulCupCounter extends StatefulWidget {
  const StatefulCupCounter({super.key});

  @override
  State<StatefulCupCounter> createState() => _StatefulCupCounterState();
}

class _StatefulCupCounterState extends State<StatefulCupCounter> {
  int _cups = 0;

  @override
  Widget build(BuildContext context) => CupCounter(cups: _cups, onAdd: () => setState(() => _cups++));
}

class CupCounter extends StatelessWidget {
  const CupCounter({super.key, required this.cups, required this.onAdd});

  final int cups;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('☕ × $cups', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(width: 16),
        FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Cup')),
      ],
    );
  }
}

/// Stands in for something expensive. It counts its own builds so you can
/// see the waste in the running app.
class PriceChart extends StatelessWidget {
  const PriceChart({super.key});

  static final Map<String, int> builds = {};

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorWidgetOfExactType<WastefulScreen>() != null ? 'wasteful' : 'fixed';
    final n = builds[screen] = (builds[screen] ?? 0) + 1;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 120, width: 280, child: CustomPaint(painter: _Sparkline())),
          Text('chart built $n time${n == 1 ? '' : 's'}'),
        ],
      ),
    );
  }
}

class _Sparkline extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i <= 40; i++) {
      final x = size.width * i / 40;
      final y = size.height / 2 + math.sin(i / 3) * size.height / 3 - i;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.teal
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
