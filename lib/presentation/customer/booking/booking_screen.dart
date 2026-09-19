import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../domain/entities/bike.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/entities/promo_code.dart';
import '../../../domain/entities/station.dart';
import '../../../domain/entities/wallet.dart';
import '../../../services/payment/payment_service.dart';
import '../../common/providers/auth_state_provider.dart';
import '../../common/providers/notification_providers.dart';
import '../../common/providers/payment_providers.dart';
import '../../common/providers/repository_providers.dart';
import '../../common/providers/wallet_providers.dart';
import '../auth/auth_modal.dart';
import '../bike_details/bike_details_screen.dart';
import '../explore/explore_screen.dart';
import '../profile/kyc_submission_screen.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String bikeId;

  const BookingScreen({super.key, required this.bikeId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _couponController = TextEditingController();
  int _selectedHours = 4;
  String? _pickupStationId;
  String? _returnStationId;
  bool _useWalletBalance = true;
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

  Future<void> _applyCoupon(double rentalFare) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    final repo = ref.read(promoRepositoryProvider);
    final result = await repo.validatePromo(
      code: code,
      orderAmount: rentalFare,
      orderType: PromoApplicableType.rental,
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
    final bikeAsync = ref.watch(bikeDetailsFutureProvider(widget.bikeId));
    final stationsAsync = ref.watch(stationsFutureProvider);
    final walletAsync = ref.watch(userWalletFutureProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Rental & Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: bikeAsync.when(
        data: (bike) {
          if (bike == null) return const Center(child: Text('Vehicle not found'));

          _pickupStationId ??= bike.currentStationId;
          _returnStationId ??= bike.currentStationId;

          // Pricing calculation (Server-authoritative matching formula)
          final double rentalFare = _selectedHours >= 24
              ? (_selectedHours / 24).ceil() * bike.dailyRate
              : _selectedHours * bike.hourlyRate;
          final double gstAmount = (rentalFare * 0.18);
          final double discountedRentalFare = (rentalFare - _discountAmount).clamp(0.0, double.infinity);
          final double grossPayable = discountedRentalFare + gstAmount + bike.securityDeposit;

          final wallet = walletAsync.value;
          final double availableWallet = wallet?.totalBalance ?? 0.0;
          final double walletDeduction = _useWalletBalance
              ? (availableWallet > grossPayable ? grossPayable : availableWallet)
              : 0.0;
          final double netGatewayPayable = (grossPayable - walletDeduction).clamp(0.0, double.infinity);

          final pricing = PricingBreakdown(
            rentalFare: discountedRentalFare,
            gstAmount: gstAmount,
            securityDeposit: bike.securityDeposit,
            totalPayable: grossPayable,
          );

          if (isDesktop) {
            // Desktop Two-Column Split Checkout
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Configuration (Duration & Hubs)
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BikeSummaryMiniCard(bike: bike),
                              const SizedBox(height: 24),
                              _buildDurationSection(),
                              const SizedBox(height: 24),
                              _buildHubsSection(stationsAsync),
                              const SizedBox(height: 24),
                              _buildKycNotice(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Right Column: Sticky Fare Breakdown & Action
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildPromoEngineBox(rentalFare),
                            const SizedBox(height: 16),
                            if (wallet != null && wallet.totalBalance > 0)
                              _buildWalletToggle(wallet, walletDeduction),
                            const SizedBox(height: 16),
                            _buildFareBreakdownCard(
                              bike: bike,
                              originalRentalFare: rentalFare,
                              discountAmount: _discountAmount,
                              walletDeduction: walletDeduction,
                              grossPayable: grossPayable,
                              netGatewayPayable: netGatewayPayable,
                              pricing: pricing,
                              onConfirm: () => _handleConfirmBooking(
                                bike: bike,
                                pricing: pricing,
                                grossPayable: grossPayable,
                                walletDeduction: walletDeduction,
                                netGatewayPayable: netGatewayPayable,
                              ),
                            ),
                          ],
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
                      _BikeSummaryMiniCard(bike: bike),
                      const SizedBox(height: 20),
                      _buildDurationSection(),
                      const SizedBox(height: 20),
                      _buildHubsSection(stationsAsync),
                      const SizedBox(height: 20),
                      _buildPromoEngineBox(rentalFare),
                      const SizedBox(height: 16),
                      if (wallet != null && wallet.totalBalance > 0)
                        _buildWalletToggle(wallet, walletDeduction),
                      const SizedBox(height: 16),
                      _buildFareBreakdownCard(
                        bike: bike,
                        originalRentalFare: rentalFare,
                        discountAmount: _discountAmount,
                        walletDeduction: walletDeduction,
                        grossPayable: grossPayable,
                        netGatewayPayable: netGatewayPayable,
                        pricing: pricing,
                        isEmbedded: true,
                      ),
                    ],
                  ),
                ),
              ),
              // Mobile Bottom Sticky Confirmation Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.lightSurface,
                  border: Border(top: BorderSide(color: AppColors.lightBorder)),
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleConfirmBooking(
                              bike: bike,
                              pricing: pricing,
                              grossPayable: grossPayable,
                              walletDeduction: walletDeduction,
                              netGatewayPayable: netGatewayPayable,
                            ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            netGatewayPayable == 0
                                ? '1-Tap Pay with VeloCash • ${CurrencyFormatter.format(grossPayable)}'
                                : 'Confirm Booking • ${CurrencyFormatter.format(netGatewayPayable)}',
                          ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, s) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Rental Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [4, 8, 12, 24, 48, 72].map((hours) {
            final isSelected = _selectedHours == hours;
            final label = hours >= 24 ? '${hours ~/ 24} Day(s)' : '$hours Hours';
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedHours = hours;
                  if (_appliedPromo != null) {
                    final newBaseFare = hours >= 24
                        ? (hours / 24).ceil() * 499.0
                        : hours * 69.0;
                    _discountAmount = _appliedPromo!.calculateDiscount(newBaseFare);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHubsSection(AsyncValue<List<Station>> stationsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pickup & Return Hubs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        stationsAsync.when(
          data: (stations) => Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _pickupStationId,
                decoration: const InputDecoration(
                  labelText: 'Pickup Station (Keyless / QR Handover)',
                  prefixIcon: Icon(Icons.trip_origin_rounded, color: AppColors.primary),
                ),
                items: stations.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text('${s.name} (${s.city})'),
                )).toList(),
                onChanged: (val) {
                  setState(() => _pickupStationId = val);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _returnStationId,
                decoration: const InputDecoration(
                  labelText: 'Return Station (Any Hyderabad Hub)',
                  prefixIcon: Icon(Icons.pin_drop_rounded, color: AppColors.secondary),
                ),
                items: stations.map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text('${s.name} (${s.city})'),
                )).toList(),
                onChanged: (val) {
                  setState(() => _returnStationId = val);
                },
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildPromoEngineBox(double rentalFare) {
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
              Text('Have a Coupon Code?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                          'Saved ${CurrencyFormatter.format(_discountAmount)} on this ride!',
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
                      hintText: 'e.g. BLRCOMMUTE, START50',
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
                  onPressed: _isValidatingPromo ? null : () => _applyCoupon(rentalFare),
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

  Widget _buildWalletToggle(Wallet wallet, double walletDeduction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pay with VeloCash Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  'Available: ${CurrencyFormatter.format(wallet.totalBalance)} (Deducting ${CurrencyFormatter.format(walletDeduction)})',
                  style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Switch(
            value: _useWalletBalance,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _useWalletBalance = val),
          ),
        ],
      ),
    );
  }

  Widget _buildKycNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driving License Requirement',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'An Indian Two-Wheeler Driving License is mandatory before vehicle pickup under Karnataka State transport regulations.',
                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareBreakdownCard({
    required Bike bike,
    required double originalRentalFare,
    required double discountAmount,
    required double walletDeduction,
    required double grossPayable,
    required double netGatewayPayable,
    required PricingBreakdown pricing,
    VoidCallback? onConfirm,
    bool isEmbedded = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: isEmbedded
            ? null
            : [
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
          const Text('Fare & Deposit Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _FareRow(label: 'Rental Fare ($_selectedHours hrs)', amount: originalRentalFare),
          if (discountAmount > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Coupon Discount (${_appliedPromo?.code})',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '- ${CurrencyFormatter.format(discountAmount)}',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _FareRow(label: 'GST (18% Govt. Tax)', amount: pricing.gstAmount),
          const SizedBox(height: 10),
          _FareRow(
            label: 'Refundable Security Deposit',
            amount: pricing.securityDeposit,
            isHighlighted: true,
            subtitle: '100% refunded on vehicle return',
          ),
          if (walletDeduction > 0) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VeloCash Balance Applied',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '- ${CurrencyFormatter.format(walletDeduction)}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ],
          const Divider(height: 28),
          _FareRow(
            label: netGatewayPayable == 0 ? 'Total Covered by VeloCash' : 'Net Payable via Gateway',
            amount: netGatewayPayable == 0 ? grossPayable : netGatewayPayable,
            isTotal: true,
          ),
          if (!isEmbedded && onConfirm != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : onConfirm,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      netGatewayPayable == 0
                          ? '1-Tap Pay with VeloCash • ${CurrencyFormatter.format(grossPayable)}'
                          : 'Confirm Booking • ${CurrencyFormatter.format(netGatewayPayable)}',
                    ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                netGatewayPayable == 0
                    ? '⚡ Instant Wallet Confirmation (No Payment Gateway Needed)'
                    : '🔒 Razorpay 256-bit Encrypted Checkout',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleConfirmBooking({
    required Bike bike,
    required PricingBreakdown pricing,
    required double grossPayable,
    required double walletDeduction,
    required double netGatewayPayable,
  }) async {
    var user = ref.read(authControllerProvider).value;
    if (user == null) {
      final loggedIn = await AuthModal.show(
        context,
        redirectTitle: 'Sign in to confirm booking',
      );
      if (loggedIn != true) return;
      user = ref.read(authControllerProvider).value;
    }

    if (user != null && !user.isKycVerified) {
      if (!mounted) return;
      final proceedToKyc = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.secondary),
              SizedBox(width: 8),
              Text('Driving License Required'),
            ],
          ),
          content: const Text(
            'Under Indian transport laws, a verified two-wheeler Driving License is mandatory before bike reservation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit DL Now'),
            ),
          ],
        ),
      );

      if (proceedToKyc == true && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const KycSubmissionScreen()),
        );
        user = ref.read(authControllerProvider).value;
        if (user?.isKycVerified != true) return;
      } else {
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final promoRepo = ref.read(promoRepositoryProvider);
      final walletRepo = ref.read(walletRepositoryProvider);
      final paymentService = ref.read(paymentServiceProvider);
      final emailService = ref.read(emailServiceProvider);
      final now = DateTime.now();
      final customerId = user?.id ?? 'usr_demo_customer';

      String paymentRefId = 'wallet_full';

      // 1. If there's a gateway payable amount, process Razorpay order
      if (netGatewayPayable > 0) {
        final order = await paymentService.createOrder(
          bookingId: 'temp_${now.millisecondsSinceEpoch}',
          amount: netGatewayPayable,
          customerPhone: user?.phoneNumber ?? '',
          customerEmail: user?.email ?? 'customer@veloride.in',
        );

        final paymentVerification = PaymentVerification(
          orderId: order.orderId,
          paymentId: 'pay_${now.millisecondsSinceEpoch}',
          signature: 'mock_valid_signature_hash',
        );
        final isPaid = await paymentService.verifyPayment(paymentVerification);

        if (!isPaid) {
          throw Exception('Payment verification failed. Please try another payment method.');
        }
        paymentRefId = paymentVerification.paymentId;
      }

      // 2. Finalize Booking in PostgreSQL
      final booking = await bookingRepo.createBooking(
        customerId: customerId,
        bikeId: bike.id,
        pickupStationId: _pickupStationId ?? bike.currentStationId,
        returnStationId: _returnStationId ?? bike.currentStationId,
        startTime: now.add(const Duration(minutes: 30)),
        endTime: now.add(Duration(hours: _selectedHours, minutes: 30)),
        pricing: pricing,
      );

      // 3. Debit wallet if wallet deduction used
      if (walletDeduction > 0) {
        await walletRepo.debitWallet(
          userId: customerId,
          amount: walletDeduction,
          referenceId: booking.bookingNumber,
          description: 'VeloCash used for ride ${booking.bookingNumber}',
        );
        ref.invalidate(userWalletFutureProvider);
        ref.invalidate(walletTransactionsFutureProvider);
      }

      // 4. Record Promo Redemption if applied
      if (_appliedPromo != null) {
        await promoRepo.recordPromoRedemption(_appliedPromo!.code);
      }

      // 5. Trigger Email Receipt
      if (user?.email != null && user!.email!.isNotEmpty) {
        await emailService.sendBookingReceipt(
          toEmail: user.email!,
          customerName: user.fullName,
          bookingNumber: booking.bookingNumber,
          amountPaid: grossPayable,
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
                Text('Booking & Payment Confirmed!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking Ref: ${booking.bookingNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Payment Ref: $paymentRefId'),
                const SizedBox(height: 6),
                Text('Vehicle: ${bike.name} (${bike.registrationNumber})'),
                const SizedBox(height: 6),
                Text('Total Paid: ${CurrencyFormatter.format(grossPayable)}'),
                if (walletDeduction > 0) ...[
                  const SizedBox(height: 6),
                  Text('Paid from VeloCash: ${CurrencyFormatter.format(walletDeduction)}',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
                if (_discountAmount > 0) ...[
                  const SizedBox(height: 6),
                  Text('Coupon Savings: ${CurrencyFormatter.format(_discountAmount)} (${_appliedPromo?.code})',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 6),
                Text('Deposit Held: ${CurrencyFormatter.format(bike.securityDeposit)} (100% Refundable to VeloCash)'),
                const SizedBox(height: 12),
                const Text(
                  'Your reservation is active. Please proceed to the hub for instant keyless QR vehicle handover.',
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
                child: const Text('View My Bookings'),
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

class _BikeSummaryMiniCard extends StatelessWidget {
  final Bike bike;

  const _BikeSummaryMiniCard({required this.bike});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              bike.imageUrl,
              width: 80,
              height: 55,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80,
                height: 55,
                color: AppColors.primaryLight,
                child: const Icon(Icons.two_wheeler, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bike.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text('${bike.brand} • ${bike.model} • ${bike.registrationNumber}', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${CurrencyFormatter.format(bike.hourlyRate)}/hr',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;
  final bool isHighlighted;
  final String? subtitle;

  const _FareRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.isHighlighted = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : (isHighlighted ? FontWeight.w600 : FontWeight.normal),
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? AppColors.textPrimaryLight : (isHighlighted ? AppColors.primary : AppColors.textSecondaryLight),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 11, color: AppColors.success),
              ),
          ],
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
            color: isTotal ? AppColors.primary : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
