import 'package:flutter_test/flutter_test.dart';
import 'package:focus_forward/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const FocusForwardApp());
    await tester.pump();
    // Basic smoke test - the app should launch without errors
    expect(find.byType(FocusForwardApp), findsOneWidget);
  });
}
