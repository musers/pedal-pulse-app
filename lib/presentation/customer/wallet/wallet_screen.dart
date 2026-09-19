import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../domain/entities/wallet.dart';
import '../../common/providers/auth_state_provider.dart';
import '../../common/providers/repository_providers.dart';
import '../../common/providers/wallet_providers.dart';
import '../auth/auth_modal.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _referralInputController = TextEditingController();
  bool _isProcessingTopUp = false;

  @override
  void dispose() {
    _referralInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;
    final walletAsync = ref.watch(userWalletFutureProvider);
    final transactionsAsync = ref.watch(walletTransactionsFutureProvider);
    final referralInfoAsync = ref.watch(userReferralInfoFutureProvider);
    final topUpPackagesAsync = ref.watch(topUpPackagesFutureProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('VeloCash Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Sign in to access your VeloCash Wallet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enjoy instant deposit refunds, top-up bonus cashbacks, and 1-tap checkout.',
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
        title: const Text('VeloCash Wallet & Rewards', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Wallet',
            onPressed: () {
              ref.invalidate(userWalletFutureProvider);
              ref.invalidate(walletTransactionsFutureProvider);
              ref.invalidate(userReferralInfoFutureProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: walletAsync.when(
        data: (wallet) {
          if (wallet == null) return const Center(child: CircularProgressIndicator());

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userWalletFutureProvider);
              ref.invalidate(walletTransactionsFutureProvider);
              ref.invalidate(userReferralInfoFutureProvider);
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // VeloCash Balance Card
                      _buildBalanceCard(wallet),

                      const SizedBox(height: 24),

                      // Top-Up Packages Section
                      const Text(
                        'Instant Wallet Top-Up (With Bonus Cash)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      topUpPackagesAsync.when(
                        data: (packages) => _buildTopUpPackagesGrid(packages, user.id, isDesktop),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const SizedBox(),
                      ),

                      const SizedBox(height: 24),

                      // Referral Program Banner
                      referralInfoAsync.when(
                        data: (referral) => referral != null ? _buildReferralBanner(referral, user.id) : const SizedBox(),
                        loading: () => const SizedBox(),
                        error: (e, s) => const SizedBox(),
                      ),

                      const SizedBox(height: 24),

                      // Instant Deposit Refund Guarantee Callout
                      _buildDepositRefundCallout(),

                      const SizedBox(height: 28),

                      // Transaction History Ledger
                      const Text(
                        'VeloCash Transaction History',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      transactionsAsync.when(
                        data: (transactions) => _buildTransactionList(transactions),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, s) => Center(child: Text('Error: $err')),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, s) => Center(child: Text('Error loading wallet: $err')),
      ),
    );
  }

  Widget _buildBalanceCard(Wallet wallet) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: AppColors.secondaryLight, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'VeloCash Digital Balance',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Saved ${CurrencyFormatter.format(wallet.totalSaved)}',
                  style: const TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(wallet.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Main Cash Balance', style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(wallet.mainBalance),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
              Container(height: 24, width: 1, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Promotional Bonus Cash', style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(wallet.bonusBalance),
                      style: const TextStyle(color: AppColors.secondaryLight, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpPackagesGrid(List<WalletTopUpPackage> packages, String userId, bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: packages.map((pkg) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: pkg.bonusAmount > 0 ? AppColors.primary : AppColors.lightBorder,
                    width: pkg.bonusAmount > 0 ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pkg.tag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pkg.tag!,
                          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(pkg.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                    if (pkg.bonusAmount > 0)
                      Text(
                        '+ ${CurrencyFormatter.format(pkg.bonusAmount)} Bonus Cash',
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                      )
                    else
                      const Text(
                        'Direct Cash Credit',
                        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pkg.bonusAmount > 0 ? AppColors.primary : AppColors.lightSurfaceCard,
                        foregroundColor: pkg.bonusAmount > 0 ? Colors.white : AppColors.textPrimaryLight,
                        minimumSize: const Size.fromHeight(36),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      onPressed: _isProcessingTopUp ? null : () => _handleTopUp(pkg, userId),
                      child: const Text('Add Money', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReferralBanner(ReferralInfo referral, String userId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.card_giftcard_rounded, color: AppColors.secondary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Invite Friends & Earn ₹100 VeloCash',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Text(
                '${referral.referralCount} Friends Invited (Earned ${CurrencyFormatter.format(referral.totalEarned)})',
                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Your friend gets ₹100 off on their first ride, and you get ₹100 VeloCash added directly to your wallet once they complete their trip.',
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Referral Code Display Container
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        referral.referralCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: referral.referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Referral code copied to clipboard!')),
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Copy Code', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.redeem_rounded, size: 16),
                label: const Text('Redeem Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  minimumSize: const Size(130, 48),
                ),
                onPressed: () => _showRedeemDialog(userId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepositRefundCallout() {
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
          Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instant Security Deposit Refunds with VeloCash',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  'No waiting 3-5 bank business days. Security deposits are credited instantly to your VeloCash wallet on return inspection for zero-friction future rides.',
                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<WalletTransaction> transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Text('No transactions yet. Top-up or complete a ride to see ledger history.'),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isPositive = tx.isPositive;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isPositive ? AppColors.success : AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(tx.description, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(dateFormat.format(tx.createdAt), style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                '${isPositive ? "+" : "-"} ${CurrencyFormatter.format(tx.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleTopUp(WalletTopUpPackage pkg, String userId) async {
    setState(() => _isProcessingTopUp = true);
    try {
      final paymentId = 'pay_topup_${DateTime.now().millisecondsSinceEpoch}';
      await ref.read(walletRepositoryProvider).topUpWallet(
        userId: userId,
        amount: pkg.amount,
        bonusAmount: pkg.bonusAmount,
        paymentId: paymentId,
      );

      ref.invalidate(userWalletFutureProvider);
      ref.invalidate(walletTransactionsFutureProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added ${CurrencyFormatter.format(pkg.totalCredited)} to your VeloCash wallet!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingTopUp = false);
    }
  }

  void _showRedeemDialog(String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.redeem_rounded, color: AppColors.secondary),
            SizedBox(width: 8),
            Text('Redeem Friend\'s Code'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the referral code shared by your friend to get ₹100 VeloCash instantly.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _referralInputController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Referral Code',
                hintText: 'e.g. VELO-AMIT-482',
                prefixIcon: Icon(Icons.vpn_key_rounded, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final code = _referralInputController.text.trim();
              if (code.isEmpty) return;
              try {
                await ref.read(walletRepositoryProvider).redeemReferralCode(
                  userId: userId,
                  referralCode: code,
                );
                ref.invalidate(userWalletFutureProvider);
                ref.invalidate(walletTransactionsFutureProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Referral reward of ₹100 credited to your VeloCash wallet!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Claim ₹100'),
          ),
        ],
      ),
    );
  }
}
