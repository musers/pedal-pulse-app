import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../domain/entities/bike.dart';
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
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: bikeAsync.when(
        data: (bike) {
          if (bike == null) {
            return const Center(child: Text('Vehicle not found'));
          }

          if (isDesktop) {
            // Desktop Two-Column Split Layout
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Gallery, Specs & Inclusions
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hero Gallery Card
                              _HeroImageCard(bike: bike),
                              const SizedBox(height: 24),
                              _VehicleHeader(bike: bike),
                              const SizedBox(height: 20),
                              _SpecRow(bike: bike),
                              const SizedBox(height: 24),
                              _InclusionsSection(bike: bike),
                              const SizedBox(height: 20),
                              _DepositGuaranteeCard(depositAmount: bike.securityDeposit),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Right Column: Sticky Booking Action Card
                      Expanded(
                        flex: 2,
                        child: _DesktopBookingCard(bike: bike),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Mobile / Tablet Single-Column Layout
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroImageCard(bike: bike, isMobile: true),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _VehicleHeader(bike: bike),
                            const SizedBox(height: 20),
                            _SpecRow(bike: bike),
                            const SizedBox(height: 24),
                            _InclusionsSection(bike: bike),
                            const SizedBox(height: 20),
                            _DepositGuaranteeCard(depositAmount: bike.securityDeposit),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Mobile Bottom Sticky Action Bar
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

class _HeroImageCard extends StatelessWidget {
  final Bike bike;
  final bool isMobile;

  const _HeroImageCard({required this.bike, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: isMobile ? 16 / 10 : 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              bike.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.lightSurfaceCard,
                child: const Icon(Icons.electric_moped, size: 64, color: AppColors.primary),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bike.batteryPercentage != null) ...[
                      const Icon(Icons.bolt_rounded, size: 16, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        '${bike.batteryPercentage}% Battery',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ] else ...[
                      const Icon(Icons.local_gas_station_rounded, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      const Text(
                        'Petrol Fleet',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bike.isAvailable ? AppColors.success : AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bike.isAvailable ? 'Available for Instant Dispatch' : 'Currently Reserved',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  final Bike bike;

  const _VehicleHeader({required this.bike});

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
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
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final Bike bike;

  const _SpecRow({required this.bike});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SpecItem(
          icon: Icons.speed_rounded,
          label: 'Estimated Range',
          value: '${bike.rangeKm} km',
        ),
        const SizedBox(width: 12),
        _SpecItem(
          icon: bike.batteryPercentage != null ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
          label: bike.batteryPercentage != null ? 'Power State' : 'Fuel Engine',
          value: bike.batteryPercentage != null ? '${bike.batteryPercentage}% Charged' : 'Petrol (4-Stroke)',
        ),
        const SizedBox(width: 12),
        _SpecItem(
          icon: Icons.security_rounded,
          label: 'Refundable Deposit',
          value: CurrencyFormatter.format(bike.securityDeposit),
        ),
      ],
    );
  }
}

class _InclusionsSection extends StatelessWidget {
  final Bike bike;

  const _InclusionsSection({required this.bike});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Included with Every Rental',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...bike.features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(f, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        )),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text('Two ISI-certified sanitized helmets provided free', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text('24/7 Roadside Assistance & GPS safety monitoring', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _DepositGuaranteeCard extends StatelessWidget {
  final double depositAmount;

  const _DepositGuaranteeCard({required this.depositAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '100% Refundable Security Deposit Guarantee',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your deposit of ${CurrencyFormatter.format(depositAmount)} is held securely and automatically released to your original payment method immediately upon returning the bike in good order.',
                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopBookingCard extends StatelessWidget {
  final Bike bike;

  const _DesktopBookingCard({required this.bike});

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Rental Fare Pricing',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.format(bike.hourlyRate),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Text(' / hr', style: TextStyle(fontSize: 16, color: AppColors.textSecondaryLight)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${CurrencyFormatter.format(bike.dailyRate)}/day',
                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          const Row(
            children: [
              Icon(Icons.flash_on_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Instant Keyless Hub Pickup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.badge_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Requires Indian 2-Wheeler DL', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.lock_clock_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Free cancellation up to 1 hr before', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {
              context.push('/booking/${bike.id}');
            },
            child: const Text('Proceed to Reservation & Schedule'),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '🔒 256-bit Encrypted Server Verification',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.lightSurfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1),
          ],
        ),
      ),
    );
  }
}
