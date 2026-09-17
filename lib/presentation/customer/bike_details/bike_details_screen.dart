import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../common/providers/repository_providers.dart';

final bikeDetailsFutureProvider = FutureProvider.family((ref, String bikeId) {
  final repo = ref.watch(bikeRepositoryProvider);
  return repo.getBikeById(bikeId);
});

class BikeDetailsScreen extends ConsumerWidget {
  final String bikeId;

  const BikeDetailsScreen({super.key, required this.bikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeAsync = ref.watch(bikeDetailsFutureProvider(bikeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bike Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: bikeAsync.when(
        data: (bike) {
          if (bike == null) {
            return const Center(child: Text('Bike not found'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Hero Image
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          bike.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.lightSurfaceCard,
                            child: const Icon(Icons.electric_moped, size: 64, color: AppColors.primary),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bike.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${bike.brand} • ${bike.model} • Reg: ${bike.registrationNumber}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondaryLight,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    bike.isAvailable ? 'Available Now' : 'Booked',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Highlights / Spec Grid
                            Row(
                              children: [
                                _SpecItem(
                                  icon: Icons.speed_rounded,
                                  label: 'Range',
                                  value: '${bike.rangeKm} km',
                                ),
                                const SizedBox(width: 12),
                                _SpecItem(
                                  icon: bike.batteryPercentage != null ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
                                  label: bike.batteryPercentage != null ? 'Battery' : 'Fuel',
                                  value: bike.batteryPercentage != null ? '${bike.batteryPercentage}%' : 'Petrol',
                                ),
                                const SizedBox(width: 12),
                                _SpecItem(
                                  icon: Icons.security_rounded,
                                  label: 'Deposit',
                                  value: CurrencyFormatter.format(bike.securityDeposit),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            const Text(
                              'Key Highlights & Inclusions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...bike.features.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Text(f, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            )),

                            const SizedBox(height: 20),

                            // Trust & Security Notice
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Refundable Security Deposit',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${CurrencyFormatter.format(bike.securityDeposit)} deposit is 100% refunded to your original payment method immediately upon successful bike drop-off.',
                                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Booking Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.lightSurface,
                  border: Border(top: BorderSide(color: AppColors.lightBorder)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Starting from', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                CurrencyFormatter.format(bike.hourlyRate),
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              const Text(' / hour', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/booking/${bike.id}');
                          },
                          child: const Text('Select Rental Time'),
                        ),
                      ),
                    ],
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
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.lightSurfaceCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1),
          ],
        ),
      ),
    );
  }
}
