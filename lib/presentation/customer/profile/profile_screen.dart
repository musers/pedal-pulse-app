import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
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
                  child: const Text('BG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bala Gangadhar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 4),
                      Text('+91 98765 00000', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14)),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.verified_rounded, color: AppColors.success, size: 16),
                          SizedBox(width: 4),
                          Text('KYC Verified (DL Approved)', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text('Rental Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.badge_outlined,
            title: 'Driving License Details',
            subtitle: 'KA-01-2022-0049210',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Security Deposit Account',
            subtitle: 'Refunds returned to source payment method',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Rental Agreements & Invoices',
            subtitle: 'View GST compliant tax invoices',
            onTap: () {},
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
            subtitle: 'Helmet rules, traffic fines, fuel guidelines',
            onTap: () {},
          ),

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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondaryLight),
        onTap: onTap,
      ),
    );
  }
}
