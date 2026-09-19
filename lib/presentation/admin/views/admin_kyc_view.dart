import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user_profile.dart';

class AdminKycView extends ConsumerStatefulWidget {
  const AdminKycView({super.key});

  @override
  ConsumerState<AdminKycView> createState() => _AdminKycViewState();
}

class _AdminKycViewState extends ConsumerState<AdminKycView> {
  // Demo customer queue
  final List<Map<String, dynamic>> _kycQueue = [
    {
      'id': 'usr_demo_customer_01',
      'name': 'Bala Gangadhar',
      'phone': '+91 98765 00000',
      'dlNumber': 'KA-01-2022-0049210',
      'status': KycStatus.verified,
      'docUrl': 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?auto=format&fit=crop&w=600&q=80',
      'submittedAt': '18 Sep 2026, 11:30 AM',
    },
    {
      'id': 'usr_pending_02',
      'name': 'Rahul Sharma',
      'phone': '+91 98123 45678',
      'dlNumber': 'KA-03-2023-0019283',
      'status': KycStatus.pendingReview,
      'docUrl': 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80',
      'submittedAt': '19 Sep 2026, 09:15 AM',
    },
    {
      'id': 'usr_pending_03',
      'name': 'Priya Nair',
      'phone': '+91 99456 78901',
      'dlNumber': 'KA-51-2021-0083719',
      'status': KycStatus.pendingReview,
      'docUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=600&q=80',
      'submittedAt': '19 Sep 2026, 10:45 AM',
    },
  ];

  void _updateKyc(int index, KycStatus newStatus) {
    setState(() {
      _kycQueue[index]['status'] = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == KycStatus.verified
              ? 'Approved ${_kycQueue[index]['name']}\'s Driving License.'
              : 'Rejected ${_kycQueue[index]['name']}\'s Driving License. Notification sent.',
        ),
        backgroundColor: newStatus == KycStatus.verified ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Customer Driving License (KYC) Review Queue',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 4),
          const Text(
            'Review submitted Indian two-wheeler Driving Licenses to ensure compliance with transport safety laws.',
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Cards List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _kycQueue.length,
            itemBuilder: (context, index) {
              final item = _kycQueue[index];
              final KycStatus status = item['status'] as KycStatus;
              final isPending = status == KycStatus.pendingReview;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.lightBorder),
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
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                child: Text(
                                  (item['name'] as String).substring(0, 1),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('${item['phone']} • Submitted: ${item['submittedAt']}', style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? AppColors.warning.withValues(alpha: 0.12)
                                  : (status == KycStatus.verified ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status == KycStatus.verified
                                  ? 'Verified'
                                  : (status == KycStatus.pendingReview ? 'Action Required' : 'Rejected'),
                              style: TextStyle(
                                color: isPending
                                    ? AppColors.warning
                                    : (status == KycStatus.verified ? AppColors.success : AppColors.error),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // DL Info Row
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('DL Number: ${item['dlNumber']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const Spacer(),
                          const Text('Class: MCWG / MCWOG Approved', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                        ],
                      ),

                      if (isPending) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                                label: const Text('Reject (Blur / Invalid)', style: TextStyle(color: AppColors.error)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                                onPressed: () => _updateKyc(index, KycStatus.rejected),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Approve Driving License'),
                                onPressed: () => _updateKyc(index, KycStatus.verified),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
