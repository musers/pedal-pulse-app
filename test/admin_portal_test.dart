import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/presentation/admin/admin_portal_screen.dart';
import 'package:rental_subscription_platform/presentation/admin/views/admin_fleet_view.dart';

void main() {
  testWidgets('AdminPortalScreen renders metric cards and navigation', (WidgetTester tester) async {
    // Set a wide screen size (desktop view)
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminPortalScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Admin Portal title and components
    expect(find.byType(AdminPortalScreen), findsOneWidget);
    expect(find.byType(AdminFleetView), findsOneWidget);
    expect(find.text('Fleet Inventory & Hub Operations'), findsOneWidget);
    expect(find.text('Total Fleet'), findsOneWidget);
    expect(find.text('Ready for Rent'), findsOneWidget);
  });
}
