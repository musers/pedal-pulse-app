import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/entities/subscription_plan.dart';
import '../../common/providers/auth_state_provider.dart';
import '../../common/providers/repository_providers.dart';
import '../auth/auth_modal.dart';

final userBookingsFutureProvider = FutureProvider<List<Booking>>((ref) {
  final repo = ref.watch(bookingRepositoryProvider);
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return Future.value([]);
  return repo.getUserBookings(user.id);
});

final userSubscriptionsFutureProvider = FutureProvider<List<UserSubscription>>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return Future.value([]);
  return repo.getUserSubscriptions(user.id);
});

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings & Passes', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Sign in to view your bookings and passes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track active rentals, weekly/monthly subscriptions, security deposits and GST receipts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.phone_android_rounded),
                  label: const Text('Login with Mobile Number'),
                  onPressed: () => AuthModal.show(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings & Mobility Passes', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.two_wheeler_rounded, size: 18), text: 'Hourly & Daily Rentals'),
            Tab(icon: Icon(Icons.card_membership_rounded, size: 18), text: 'Weekly & Monthly Passes'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(userBookingsFutureProvider);
              ref.invalidate(userSubscriptionsFutureProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Rentals
          _buildRentalsTab(isDesktop),
          // Tab 2: Subscriptions
          _buildSubscriptionsTab(isDesktop),
        ],
      ),
    );
  }

  Widget _buildRentalsTab(bool isDesktop) {
    final bookingsAsync = ref.watch(userBookingsFutureProvider);

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text('No rental bookings found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Reserve a bike from the Explore fleet to view trip itineraries here.', style: TextStyle(color: AppColors.textSecondaryLight)),
              ],
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(userBookingsFutureProvider),
              child: ListView.separated(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                itemCount: bookings.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _BookingCard(booking: booking);
                },
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, s) => Center(child: Text('Error loading bookings: $err')),
    );
  }

  Widget _buildSubscriptionsTab(bool isDesktop) {
    final subscriptionsAsync = ref.watch(userSubscriptionsFutureProvider);

    return subscriptionsAsync.when(
      data: (subscriptions) {
        if (subscriptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_membership_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text('No active subscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Subscribe to weekly or monthly passes with zero maintenance and unlimited km.', style: TextStyle(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Explore Subscription Passes'),
                  onPressed: () => context.push('/subscriptions'),
                ),
              ],
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(userSubscriptionsFutureProvider),
              child: ListView.separated(
                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                itemCount: subscriptions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final sub = subscriptions[index];
                  return _UserSubscriptionCard(
                    subscription: sub,
                    onStatusUpdate: (newStatus) async {
                      await ref.read(subscriptionRepositoryProvider).updateSubscriptionStatus(
                        subscriptionId: sub.id,
                        status: newStatus,
                      );
                      ref.invalidate(userSubscriptionsFutureProvider);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, s) => Center(child: Text('Error loading subscriptions: $err')),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppColors.info;
      case BookingStatus.active:
        return AppColors.success;
      case BookingStatus.completed:
        return AppColors.primary;
      case BookingStatus.cancelled:
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Confirmed • Ready for Pickup';
      case BookingStatus.active:
        return 'Trip in Progress';
      case BookingStatus.completed:
        return 'Completed • Deposit Released';
      case BookingStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Pending Confirmation';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.bookingNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Reserved on ${dateFormat.format(booking.createdAt)}',
                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(booking.status).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(booking.startTime)}  →  ${dateFormat.format(booking.endTime)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Amount Paid', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(booking.pricing.totalPayable),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Security Deposit', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            '${CurrencyFormatter.format(booking.pricing.securityDeposit)} (${booking.depositStatus.name.toUpperCase()})',
                            style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text('Record Hub Pickup (Start Trip)'),
                      onPressed: () async {
                        await ref.read(bookingRepositoryProvider).recordPickup(booking.id, 5000);
                        ref.invalidate(userBookingsFutureProvider);
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (booking.status == BookingStatus.active) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Return Vehicle to Hub (End Trip & Refund Deposit)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      onPressed: () async {
                        await ref.read(bookingRepositoryProvider).recordReturn(booking.id, 5045, booking.returnStationId);
                        ref.invalidate(userBookingsFutureProvider);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UserSubscriptionCard extends StatelessWidget {
  final UserSubscription subscription;
  final ValueChanged<UserSubscriptionStatus> onStatusUpdate;

  const _UserSubscriptionCard({
    required this.subscription,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final daysRemaining = subscription.endDate.difference(DateTime.now()).inDays;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.card_membership_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.subscriptionNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          subscription.planName,
                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (subscription.status == UserSubscriptionStatus.active ? AppColors.success : AppColors.secondary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (subscription.status == UserSubscriptionStatus.active ? AppColors.success : AppColors.secondary)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    subscription.status.name.toUpperCase(),
                    style: TextStyle(
                      color: subscription.status == UserSubscriptionStatus.active ? AppColors.success : AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(subscription.startDate)} → ${dateFormat.format(subscription.endDate)} (${daysRemaining > 0 ? "$daysRemaining days remaining" : "Completed"})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (subscription.assignedBikeName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.electric_moped_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned Vehicle: ${subscription.assignedBikeName}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Pass Fee Paid', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(subscription.amountPaid),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Deposit Held (Refundable)', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            CurrencyFormatter.format(subscription.securityDeposit),
                            style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (subscription.status == UserSubscriptionStatus.active) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      onPressed: () => onStatusUpdate(UserSubscriptionStatus.paused),
                      child: const Text('Pause Pass (Up to 5 Days)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onStatusUpdate(UserSubscriptionStatus.completed),
                      child: const Text('Complete & Refund Deposit'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
