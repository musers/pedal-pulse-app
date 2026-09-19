import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/user_profile.dart';
import '../../common/providers/auth_state_provider.dart';
import '../../common/providers/wallet_providers.dart';
import '../auth/auth_modal.dart';
import 'kyc_submission_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final walletAsync = ref.watch(userWalletFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card or Login Prompt
          if (user != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightSurfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                          : 'VR',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName.isNotEmpty ? user.fullName : 'VeloRide Rider',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.phoneNumber,
                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        _KycBadge(status: user.kycStatus),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.account_circle_outlined, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'Login to manage your bookings & rentals',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Instant OTP login with your Indian phone number.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('Sign In / Register with Mobile'),
                    onPressed: () => AuthModal.show(context),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // VeloCash Digital Wallet Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, Color(0xFF003828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
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
                        Icon(Icons.account_balance_wallet_rounded, color: AppColors.secondary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'VeloCash Digital Wallet',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '1-Tap Checkout Active',
                        style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                walletAsync.when(
                  data: (wallet) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(wallet?.totalBalance ?? 0.0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Main: ${CurrencyFormatter.format(wallet?.mainBalance ?? 0.0)} • Bonus: ${CurrencyFormatter.format(wallet?.bonusBalance ?? 0.0)}',
                            style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryDark),
                        label: const Text('Manage', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.push('/wallet'),
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (e, s) => Text('Error loading wallet: $e', style: const TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => context.push('/wallet'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.card_giftcard_rounded, color: AppColors.secondary, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Refer friends & get ₹100 VeloCash bonus on each referral',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text('Rental & Identity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'VeloCash Wallet & Referral Rewards',
            subtitle: 'Add money with bonus cashback, view ledger & invite friends',
            trailingWidget: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondaryLight),
            onTap: () => context.push('/wallet'),
          ),
          _SettingsTile(
            icon: Icons.badge_outlined,
            title: 'Driving License Details (KYC)',
            subtitle: user?.drivingLicenseNumber != null
                ? '${user!.drivingLicenseNumber} (${user.kycStatus.name})'
                : 'Action Required: Upload Two-Wheeler DL to book',
            trailingWidget: user?.isKycVerified == true
                ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                : const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondaryLight),
            onTap: () {
              if (user == null) {
                AuthModal.show(context, redirectTitle: 'Login to verify KYC');
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const KycSubmissionScreen()),
                );
              }
            },
          ),
          _SettingsTile(
            icon: Icons.security_rounded,
            title: 'Security Deposit Refunds',
            subtitle: 'Instant refund credited back to VeloCash or source bank account',
            onTap: () => context.push('/wallet'),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Rental Agreements & Tax Invoices',
            subtitle: 'View GST compliant tax receipts via Resend',
            onTap: () {},
          ),

          const SizedBox(height: 24),
          const Text('Administrative Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Hub Fleet & Dispatch Portal',
            subtitle: 'Manage station inventory, check-in, check-out & returns',
            trailingWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Admin / Staff', style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            onTap: () => context.push('/admin'),
          ),

          const SizedBox(height: 24),

          const Text('Support & Safety', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.phone_in_talk_outlined,
            title: 'Roadside Assistance & Support',
            subtitle: AppConstants.supportPhone,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.policy_outlined,
            title: 'Terms of Service & Rental Policy',
            subtitle: 'Helmet rules, traffic fines, fuel & security policies',
            onTap: () {},
          ),

          if (user != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out from VeloRide?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authControllerProvider.notifier).signOut();
                }
              },
            ),
          ],

          const SizedBox(height: 32),

          Center(
            child: Text(
              '${AppConstants.appName} • v1.0.0 (Clean Architecture)',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

class _KycBadge extends StatelessWidget {
  final KycStatus status;

  const _KycBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case KycStatus.verified:
        color = AppColors.success;
        label = 'KYC Verified (DL Approved)';
        icon = Icons.verified_rounded;
        break;
      case KycStatus.pendingReview:
        color = AppColors.warning;
        label = 'KYC Under Review';
        icon = Icons.pending_actions_rounded;
        break;
      case KycStatus.rejected:
        color = AppColors.error;
        label = 'KYC Rejected - Re-upload';
        icon = Icons.cancel_outlined;
        break;
      case KycStatus.notSubmitted:
        color = AppColors.secondary;
        label = 'KYC Pending (Upload DL)';
        icon = Icons.info_outline;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
        trailing: trailingWidget ?? const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondaryLight),
        onTap: onTap,
      ),
    );
  }
}
