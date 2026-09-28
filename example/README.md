# rebuild_budget example

Two versions of the same screen: **Wasteful** calls `setState` at the top, so every tap
rebuilds the chart; **Fixed** keeps the counter's state local and the chart `const`.

- `flutter run -d chrome` shows a live "chart built N times" counter on each tab.
- `flutter test` runs [`test/budget_test.dart`](test/budget_test.dart), which budgets both screens.
