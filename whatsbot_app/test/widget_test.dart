import 'package:flutter_test/flutter_test.dart';
import 'package:whatsbot_app/main.dart';

void main() {
  testWidgets('WhatsBot app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WhatsBotApp());
    expect(find.text('WhatsBot'), findsOneWidget);
  });
}
