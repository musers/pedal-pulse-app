import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../common/providers/auth_state_provider.dart';
import 'views/admin_dispatch_view.dart';
import 'views/admin_fleet_view.dart';
import 'views/admin_kyc_view.dart';
import 'views/admin_promo_view.dart';
import 'views/admin_return_view.dart';
import 'views/admin_subscription_view.dart';

class AdminPortalScreen extends ConsumerStatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  ConsumerState<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends ConsumerState<AdminPortalScreen> {
  int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'Fleet & Operations',
      'icon': Icons.dashboard_outlined,
      'selectedIcon': Icons.dashboard_rounded,
      'view': const AdminFleetView(),
    },
    {
      'title': 'Dispatch Desk',
      'icon': Icons.key_outlined,
      'selectedIcon': Icons.key_rounded,
      'view': const AdminDispatchView(),
    },
    {
      'title': 'Return & Intake',
      'icon': Icons.assignment_turned_in_outlined,
      'selectedIcon': Icons.assignment_turned_in_rounded,
      'view': const AdminReturnView(),
    },
    {
      'title': 'KYC Verification',
      'icon': Icons.verified_user_outlined,
      'selectedIcon': Icons.verified_user_rounded,
      'view': const AdminKycView(),
    },
    {
      'title': 'Promo & Coupons',
      'icon': Icons.discount_outlined,
      'selectedIcon': Icons.discount_rounded,
      'view': const AdminPromoView(),
    },
    {
      'title': 'Subscriptions',
      'icon': Icons.card_membership_outlined,
      'selectedIcon': Icons.card_membership_rounded,
      'view': const AdminSubscriptionView(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '${AppConstants.appName} • Hub Operations Portal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Admin: ${user?.fullName ?? "Manager"} • Hyderabad Hubs',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.exit_to_app_rounded, size: 18),
            label: const Text('Customer App'),
            onPressed: () => context.go('/'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // Desktop Navigation Rail / Sidebar
          if (isDesktop)
            NavigationRail(
              selectedIndex: _selectedTabIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedTabIndex = index);
              },
              extended: true,
              minExtendedWidth: 230,
              backgroundColor: AppColors.lightSurface,
              destinations: _tabs.map((t) {
                return NavigationRailDestination(
                  icon: Icon(t['icon'] as IconData),
                  selectedIcon: Icon(t['selectedIcon'] as IconData, color: AppColors.primary),
                  label: Text(t['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),

          if (isDesktop) const VerticalDivider(thickness: 1, width: 1, color: AppColors.lightBorder),

          // Main Tab Content Area
          Expanded(
            child: _tabs[_selectedTabIndex]['view'] as Widget,
          ),
        ],
      ),
      // Mobile / Tablet Bottom Navigation
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: _selectedTabIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedTabIndex = index);
              },
              destinations: _tabs.map((t) {
                return NavigationDestination(
                  icon: Icon(t['icon'] as IconData),
                  selectedIcon: Icon(t['selectedIcon'] as IconData, color: AppColors.primary),
                  label: t['title'] as String,
                );
              }).toList(),
            )
          : null,
    );
  }
}
