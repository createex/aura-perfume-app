// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:aura_perfume_app/main.dart';

void main() {
  testWidgets('App boots and shows wordmark', (WidgetTester tester) async {
    await tester.pumpWidget(const AuraPerfumeApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('MS Parfumerie'), findsWidgets);
  });
}
