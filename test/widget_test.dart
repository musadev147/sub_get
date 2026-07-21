// This is a basic Flutter widget test for SubGet.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';
import 'package:sub_get/main.dart';

void main() {
  testWidgets('App renders splash screen showing SubGet title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our title is shown.
    expect(find.text('SubGet'), findsOneWidget);
  });
}
