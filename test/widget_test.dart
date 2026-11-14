import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marketmate/main.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = DevHttpOverrides();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('My Store'), findsOneWidget);
    await tester.pump(const Duration(seconds: 21));
  });
}
