import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:banana/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: BananaGanrajyaApp()));

    // Wait for the route and any initial frames to settle.
    await tester.pumpAndSettle();

    // Verify that the app launches and has the main 'Home' tab/header text.
    expect(find.text('Home'), findsAtLeast(1));
  });
}
