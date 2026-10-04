import 'package:fintech_platform/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money', () {
    expect(Formatters.money(6081), r'$60.81');
    expect(Formatters.money(1800000), r'$18,000.00');
    expect(Formatters.money(-4530), r'-$45.30');
    expect(Formatters.money(5), r'$0.05');
  });

  test('timeAgo', () {
    final now = DateTime(2026, 10, 4, 12);
    expect(Formatters.timeAgo(now, now: now), 'hace un momento');
    expect(
      Formatters.timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
      'hace 5 min',
    );
    expect(
      Formatters.timeAgo(now.subtract(const Duration(hours: 3)), now: now),
      'hace 3 h',
    );
  });
}
