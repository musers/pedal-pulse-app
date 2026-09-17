import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/main.dart';

void main() {
  testWidgets('VeloRideApp smoke test - app initializes without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VeloRideApp(),
      ),
    );

    // Allow timers and initial data loads to settle
    await tester.pumpAndSettle();

    // Verify root app renders
    expect(find.byType(VeloRideApp), findsOneWidget);
  });
}
