import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../domain/entities/promo_code.dart';
import '../../../domain/entities/subscription_plan.dart';
import '../../../services/payment/payment_service.dart';
import '../../common/providers/auth_state_provider.dart';
import '../../common/providers/notification_providers.dart';
import '../../common/providers/payment_providers.dart';
import '../../common/providers/repository_providers.dart';
import '../auth/auth_modal.dart';
import '../explore/explore_screen.dart';
import '../profile/kyc_submission_screen.dart';
import 'subscription_plans_screen.dart';

class SubscriptionCheckoutScreen extends ConsumerStatefulWidget {
  final String planId;

  const SubscriptionCheckoutScreen({super.key, required this.planId});

  @override
  ConsumerState<SubscriptionCheckoutScreen> createState() => _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState extends ConsumerState<SubscriptionCheckoutScreen> {
  final _couponController = TextEditingController();
  String? _pickupStationId;
  bool _autoRenew = true;
  bool _isSubmitting = false;

  PromoCode? _appliedPromo;
  double _discountAmount = 0.0;
  String? _promoError;
  bool _isValidatingPromo = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(double orderAmount) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    final repo = ref.read(promoRepositoryProvider);
    final result = await repo.validatePromo(
      code: code,
      orderAmount: orderAmount,
      orderType: PromoApplicableType.subscription,
    );

    if (!mounted) return;

    setState(() {
      _isValidatingPromo = false;
      if (result.isValid) {
        _appliedPromo = result.promoCode;
        _discountAmount = result.discountAmount;
        _promoError = null;
      } else {
        _appliedPromo = null;
        _discountAmount = 0.0;
        _promoError = result.errorMessage ?? 'Invalid coupon code';
      }
    });
  }

  void _removeCoupon() {
    setState(() {
      _appliedPromo = null;
      _discountAmount = 0.0;
      _promoError = null;
      _couponController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansFutureProvider);
    final stationsAsync = ref.watch(stationsFutureProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Subscription Pass', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: plansAsync.when(
        data: (plans) {
          final plan = plans.cast<SubscriptionPlan?>().firstWhere(
            (p) => p?.id == widget.planId,
            orElse: () => null,
          );

          if (plan == null) return const Center(child: Text('Subscription plan not found'));

          final baseFare = plan.price;
          final gstAmount = baseFare * 0.18;
          final subtotal = (baseFare + gstAmount) - _discountAmount;
          final totalPayable = (subtotal > 0 ? subtotal : 0.0) + plan.securityDeposit;

          if (isDesktop) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Plan Inclusions & Delivery Options
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PlanSummaryCard(plan: plan),
                              const SizedBox(height: 24),
                              _buildDeliveryHubPicker(stationsAsync),
                              const SizedBox(height: 24),
                              _buildAutoRenewToggle(),
                              const SizedBox(height: 24),
                              _buildKycNotice(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Right Column: Sticky Promo Engine & Fare Breakdown Card
                      Expanded(
                        flex: 2,
                        child: _buildStickyCheckoutCard(
                          plan: plan,
                          baseFare: baseFare,
                          gstAmount: gstAmount,
                          totalPayable: totalPayable,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Mobile / Narrow Layout
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PlanSummaryCard(plan: plan),
                      const SizedBox(height: 20),
                      _buildDeliveryHubPicker(stationsAsync),
                      const SizedBox(height: 20),
                      _buildPromoEngineBox(baseFare),
                      const SizedBox(height: 20),
                      _buildFareBreakdown(plan, baseFare, gstAmount, totalPayable),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.lightSurface,
                  border: Border(top: BorderSide(color: AppColors.lightBorder)),
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _handleConfirmSubscription(plan, totalPayable),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Confirm Subscription • ${CurrencyFormatter.format(totalPayable)}'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, s) => Center(child: Text('Error loading plan: $err')),
      ),
    );
  }

  Widget _buildDeliveryHubPicker(AsyncValue<List<dynamic>> stationsAsync) {
    return stationsAsync.when(
      data: (stations) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hub Pickup or Doorstep Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _pickupStationId,
            hint: const Text('Select Nearest Bengaluru Hub / Delivery Node'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_city_rounded, color: AppColors.primary),
            ),
            items: stations.map((s) => DropdownMenuItem(
              value: s.id as String,
              child: Text('${s.name} (${s.city})'),
            )).toList(),
            onChanged: (val) => setState(() => _pickupStationId = val),
          ),
        ],
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => const SizedBox(),
    );
  }

  Widget _buildAutoRenewToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.autorenew_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Auto-Renew Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Seamless mobility with automatic monthly renewal. Cancel anytime without penalty.',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: _autoRenew,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _autoRenew = val),
          ),
        ],
      ),
    );
  }

  Widget _buildKycNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: AppColors.primary, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driving License & Zero Maintenance Guarantee',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Your subscription includes 100% free scheduled maintenance, roadside breakdown rescue, and free replacement vehicles within 2 hours in Bengaluru.',
                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoEngineBox(double baseFare) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.discount_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text('Apply Coupon or Promo Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          if (_appliedPromo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_appliedPromo!.code} APPLIED',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                        ),
                        Text(
                          'You saved ${CurrencyFormatter.format(_discountAmount)} on this pass!',
                          style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                    tooltip: 'Remove Coupon',
                    onPressed: _removeCoupon,
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter code (e.g. MONTHLY500)',
                      errorText: _promoError,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(90, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isValidatingPromo ? null : () => _applyCoupon(baseFare),
                  child: _isValidatingPromo
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Apply'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFareBreakdown(
    SubscriptionPlan plan,
    double baseFare,
    double gstAmount,
    double totalPayable,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subscription Pricing Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          _FareLine(label: '${plan.name} (${plan.durationDays} Days)', amount: baseFare),
          const SizedBox(height: 8),
          _FareLine(label: 'GST (18% Govt. Tax)', amount: gstAmount),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Promo Discount (${_appliedPromo?.code})',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '- ${CurrencyFormatter.format(_discountAmount)}',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          _FareLine(
            label: 'Refundable Security Deposit',
            amount: plan.securityDeposit,
            isDeposit: true,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payable Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                CurrencyFormatter.format(totalPayable),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyCheckoutCard({
    required SubscriptionPlan plan,
    required double baseFare,
    required double gstAmount,
    required double totalPayable,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromoEngineBox(baseFare),
          const SizedBox(height: 20),
          _buildFareBreakdown(plan, baseFare, gstAmount, totalPayable),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _handleConfirmSubscription(plan, totalPayable),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Confirm Subscription • ${CurrencyFormatter.format(totalPayable)}'),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '🔒 Razorpay 256-bit Encrypted Checkout',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmSubscription(SubscriptionPlan plan, double totalPayable) async {
    var user = ref.read(authControllerProvider).value;
    if (user == null) {
      final loggedIn = await AuthModal.show(context, redirectTitle: 'Sign in to subscribe');
      if (loggedIn != true) return;
      user = ref.read(authControllerProvider).value;
    }

    if (user != null && !user.isKycVerified) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Driving License Required'),
          content: const Text('A verified Two-Wheeler Driving License is mandatory before activating long-term subscriptions.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit DL')),
          ],
        ),
      );

      if (proceed == true && mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KycSubmissionScreen()));
        user = ref.read(authControllerProvider).value;
        if (user?.isKycVerified != true) return;
      } else {
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final subRepo = ref.read(subscriptionRepositoryProvider);
      final promoRepo = ref.read(promoRepositoryProvider);
      final paymentService = ref.read(paymentServiceProvider);
      final emailService = ref.read(emailServiceProvider);
      final now = DateTime.now();

      // 1. Payment Order Creation
      final order = await paymentService.createOrder(
        bookingId: 'sub_${now.millisecondsSinceEpoch}',
        amount: totalPayable,
        customerPhone: user?.phoneNumber ?? '',
        customerEmail: user?.email ?? 'subscriber@veloride.in',
      );

      // 2. Cryptographic Verification
      final paymentVerification = PaymentVerification(
        orderId: order.orderId,
        paymentId: 'pay_sub_${now.millisecondsSinceEpoch}',
        signature: 'mock_valid_signature_hash',
      );
      final isPaid = await paymentService.verifyPayment(paymentVerification);

      if (!isPaid) throw Exception('Payment failed. Please try again.');

      // 3. Create Subscription Contract
      final subscription = await subRepo.createSubscription(
        userId: user?.id ?? 'usr_demo_customer',
        planId: plan.id,
        planName: plan.name,
        pickupStationId: _pickupStationId ?? 'st_indiranagar',
        durationDays: plan.durationDays,
        amountPaid: totalPayable,
        securityDeposit: plan.securityDeposit,
        promoCodeUsed: _appliedPromo?.code,
        discountApplied: _discountAmount,
        autoRenew: _autoRenew,
      );

      // 4. Record Promo Redemption if applied
      if (_appliedPromo != null) {
        await promoRepo.recordPromoRedemption(_appliedPromo!.code);
      }

      // 5. Send Tax Receipt
      if (user?.email != null && user!.email!.isNotEmpty) {
        await emailService.sendBookingReceipt(
          toEmail: user.email!,
          customerName: user.fullName,
          bookingNumber: subscription.subscriptionNumber,
          amountPaid: totalPayable,
        );
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success),
                SizedBox(width: 8),
                Text('Subscription Active!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contract: ${subscription.subscriptionNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Plan: ${plan.name} (${plan.durationDays} Days)'),
                const SizedBox(height: 6),
                Text('Total Paid: ${CurrencyFormatter.format(totalPayable)}'),
                if (_discountAmount > 0) ...[
                  const SizedBox(height: 6),
                  Text('Promo Savings: ${CurrencyFormatter.format(_discountAmount)} (${_appliedPromo?.code})',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Your mobility pass is active. Your assigned vehicle will be ready for keyless pickup at your selected hub.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/my-bookings');
                },
                child: const Text('View My Passes & Bookings'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _PlanSummaryCard extends StatelessWidget {
  final SubscriptionPlan plan;

  const _PlanSummaryCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${CurrencyFormatter.format(plan.price)} / ${plan.durationDays}d',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(plan.vehicleType, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
        ],
      ),
    );
  }
}

class _FareLine extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDeposit;

  const _FareLine({required this.label, required this.amount, this.isDeposit = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDeposit ? AppColors.primary : AppColors.textSecondaryLight,
            fontSize: 13,
            fontWeight: isDeposit ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDeposit ? AppColors.primary : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
