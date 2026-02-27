import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staff_app/core/app/app.dart';

void main() {
  testWidgets('App starts with home dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: StaffApp()));

    expect(find.text('Hello, Salesman'), findsOneWidget);
  });
}
