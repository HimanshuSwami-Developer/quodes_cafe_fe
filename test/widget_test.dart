import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quodes_gaming/data/models/models.dart';
import 'package:quodes_gaming/theme/colors.dart';
import 'package:quodes_gaming/theme/widgets.dart';

void main() {
  test('hexColor parses design colors', () {
    expect(hexColor('#2F6BFF'), Q.primary);
    expect(hexColor('nope', Q.bg), Q.bg);
  });

  test('countdown formatting', () {
    expect(mmss(const Duration(seconds: 598)), '09:58');
    expect(hhmmss(const Duration(seconds: 7104)), '01:58:24');
  });

  test('booking countdown uses server time', () {
    final b = Booking.fromJson({
      'id': 1,
      'status': 'locked',
      'server_time': '2026-10-31T10:00:00+05:30',
      'lock_expires_at': '2026-10-31T10:10:00+05:30',
      'total': '600.00',
    });
    expect(b.lockLeft.inSeconds, inInclusiveRange(598, 600));
    expect(b.total, 600);
  });

  testWidgets('step dots render', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StepDots(step: 2))),
    );
    expect(find.bySemanticsLabel('Step 2 of 4'), findsOneWidget);
  });
}
