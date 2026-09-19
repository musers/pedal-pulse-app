import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/admin/admin_portal_screen.dart';
import '../../presentation/customer/bike_details/bike_details_screen.dart';
import '../../presentation/customer/booking/booking_screen.dart';
import '../../presentation/customer/explore/explore_screen.dart';
import '../../presentation/customer/my_bookings/my_bookings_screen.dart';
import '../../presentation/customer/profile/profile_screen.dart';
import '../../presentation/customer/shell/app_shell.dart';
import '../../presentation/customer/subscriptions/subscription_checkout_screen.dart';
import '../../presentation/customer/subscriptions/subscription_plans_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _exploreNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'explore');
final GlobalKey<NavigatorState> _subscriptionsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'subscriptions');
final GlobalKey<NavigatorState> _bookingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'bookings');
final GlobalKey<NavigatorState> _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/admin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminPortalScreen(),
    ),
    GoRoute(
      path: '/subscription-checkout/:planId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final planId = state.pathParameters['planId'] ?? '';
        return SubscriptionCheckoutScreen(planId: planId);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch Explore
        StatefulShellBranch(
          navigatorKey: _exploreNavigatorKey,
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const ExploreScreen(),
              routes: [
                GoRoute(
                  path: 'bike/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final bikeId = state.pathParameters['id'] ?? '';
                    return BikeDetailsScreen(bikeId: bikeId);
                  },
                ),
                GoRoute(
                  path: 'booking/:id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final bikeId = state.pathParameters['id'] ?? '';
                    return BookingScreen(bikeId: bikeId);
                  },
                ),
              ],
            ),
          ],
        ),

        // Branch Subscriptions
        StatefulShellBranch(
          navigatorKey: _subscriptionsNavigatorKey,
          routes: [
            GoRoute(
              path: '/subscriptions',
              builder: (context, state) => const SubscriptionPlansScreen(),
            ),
          ],
        ),

        // Branch Bookings & Passes
        StatefulShellBranch(
          navigatorKey: _bookingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/my-bookings',
              builder: (context, state) => const MyBookingsScreen(),
            ),
          ],
        ),

        // Branch Profile
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
