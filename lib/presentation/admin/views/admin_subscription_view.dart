import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../domain/entities/subscription_plan.dart';
import '../../common/providers/repository_providers.dart';

final adminSubscriptionsFutureProvider = FutureProvider<List<UserSubscription>>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.getAllSubscriptions();
});

class AdminSubscriptionView extends ConsumerWidget {
  const AdminSubscriptionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(adminSubscriptionsFutureProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      body: subscriptionsAsync.when(
        data: (subscriptions) {
          final totalCount = subscriptions.length;
          final activeCount = subscriptions.where((s) => s.status == UserSubscriptionStatus.active).length;
          final totalRevenue = subscriptions.fold<double>(0.0, (sum, s) => sum + s.amountPaid);
          final totalDepositHeld = subscriptions.fold<double>(0.0, (sum, s) => sum + s.securityDeposit);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminSubscriptionsFutureProvider),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscriber Fleet & Contract Management',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Monitor weekly & monthly subscribers, allocated vehicles, maintenance swaps, and deposits.',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Metrics Row
                  Row(
                    children: [
                      _StatCard(
                        title: 'Active Subscribers',
                        value: '$activeCount',
                        icon: Icons.people_alt_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 14),
                      _StatCard(
                        title: 'Total Subscriptions',
                        value: '$totalCount',
                        icon: Icons.card_membership_rounded,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 14),
                      _StatCard(
                        title: 'Monthly Recurring Rev',
                        value: CurrencyFormatter.format(totalRevenue),
                        icon: Icons.currency_rupee_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 14),
                      _StatCard(
                        title: 'Security Deposits Held',
                        value: CurrencyFormatter.format(totalDepositHeld),
                        icon: Icons.security_rounded,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Active & Historical Subscriber Contracts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (subscriptions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No subscriptions found yet.'),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: subscriptions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final sub = subscriptions[index];
                        return _SubscriptionItemCard(
                          subscription: sub,
                          onStatusChanged: (newStatus) async {
                            await ref.read(subscriptionRepositoryProvider).updateSubscriptionStatus(
                              subscriptionId: sub.id,
                              status: newStatus,
                            );
                            ref.invalidate(adminSubscriptionsFutureProvider);
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, s) => Center(child: Text('Error loading subscriptions: $err')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionItemCard extends StatelessWidget {
  final UserSubscription subscription;
  final ValueChanged<UserSubscriptionStatus> onStatusChanged;

  const _SubscriptionItemCard({
    required this.subscription,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final daysRemaining = subscription.endDate.difference(DateTime.now()).inDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      subscription.subscriptionNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (subscription.status == UserSubscriptionStatus.active ? AppColors.success : AppColors.secondary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        subscription.status.name.toUpperCase(),
                        style: TextStyle(
                          color: subscription.status == UserSubscriptionStatus.active ? AppColors.success : AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${subscription.planName} • User: ${subscription.userId}',
                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                ),
                if (subscription.assignedBikeName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Assigned Vehicle: ${subscription.assignedBikeName}',
                    style: const TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    Text(
                      'Period: ${dateFormat.format(subscription.startDate)} → ${dateFormat.format(subscription.endDate)} (${daysRemaining > 0 ? "$daysRemaining days left" : "Ended"})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                    Text(
                      'Paid: ${CurrencyFormatter.format(subscription.amountPaid)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Deposit: ${CurrencyFormatter.format(subscription.securityDeposit)} (${subscription.depositStatus.toUpperCase()})',
                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status Action Dropdown
          DropdownButton<UserSubscriptionStatus>(
            value: subscription.status,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: UserSubscriptionStatus.active, child: Text('Active')),
              DropdownMenuItem(value: UserSubscriptionStatus.paused, child: Text('Pause')),
              DropdownMenuItem(value: UserSubscriptionStatus.completed, child: Text('Complete (Refund Deposit)')),
              DropdownMenuItem(value: UserSubscriptionStatus.cancelled, child: Text('Cancel')),
            ],
            onChanged: (val) {
              if (val != null && val != subscription.status) {
                onStatusChanged(val);
              }
            },
          ),
        ],
      ),
    );
  }
}
