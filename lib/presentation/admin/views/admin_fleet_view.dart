import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/bike.dart';
import '../../customer/explore/explore_screen.dart';

class AdminFleetView extends ConsumerWidget {
  const AdminFleetView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(bikesFutureProvider);
    final stationsAsync = ref.watch(stationsFutureProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Fleet Inventory & Hub Operations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 4),
          const Text(
            'Real-time vehicle availability, battery levels, and station distribution.',
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // High-level Metrics Row
          bikesAsync.when(
            data: (bikes) {
              final total = bikes.length;
              final available = bikes.where((b) => b.status == BikeStatus.available).length;
              final inUse = bikes.where((b) => b.status == BikeStatus.inUse).length;
              final reserved = bikes.where((b) => b.status == BikeStatus.reserved).length;
              final maintenance = bikes.where((b) => b.status == BikeStatus.maintenance).length;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _MetricCard(
                        title: 'Total Fleet',
                        value: '$total',
                        subtitle: 'Hyderabad EV Hubs',
                        icon: Icons.two_wheeler_rounded,
                        color: AppColors.primary,
                        width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                      ),
                      _MetricCard(
                        title: 'Ready for Rent',
                        value: '$available',
                        subtitle: '${((available / (total == 0 ? 1 : total)) * 100).toInt()}% Utilization Ready',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                        width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                      ),
                      _MetricCard(
                        title: 'Active Trips',
                        value: '${inUse + reserved}',
                        subtitle: '$inUse Riding • $reserved Reserved',
                        icon: Icons.bolt_rounded,
                        color: AppColors.secondary,
                        width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                      ),
                      _MetricCard(
                        title: 'Service & Maintenance',
                        value: '$maintenance',
                        subtitle: 'Hub Inspection',
                        icon: Icons.build_circle_outlined,
                        color: AppColors.error,
                        width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),

          const SizedBox(height: 32),

          // Fleet Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Vehicles Table',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh Fleet'),
                    onPressed: () {
                      ref.invalidate(bikesFutureProvider);
                      ref.invalidate(stationsFutureProvider);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bikes Table Card
          bikesAsync.when(
            data: (bikes) {
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.lightBorder),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: stationsAsync.when(
                    data: (stations) => DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.lightSurfaceCard),
                      columns: const [
                        DataColumn(label: Text('Vehicle', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Reg. Number', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Current Hub', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Battery / Range', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Daily Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Odometer', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: bikes.map((bike) {
                        final station = stations.firstWhere(
                          (s) => s.id == bike.currentStationId,
                          orElse: () => stations.first,
                        );

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      bike.imageUrl,
                                      width: 40,
                                      height: 28,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(Icons.two_wheeler, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(bike.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            DataCell(Text(bike.registrationNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(station.name)),
                            DataCell(_StatusBadge(status: bike.status)),
                            DataCell(
                              bike.batteryPercentage != null
                                  ? Row(
                                      children: [
                                        Icon(
                                          Icons.battery_charging_full_rounded,
                                          size: 16,
                                          color: bike.batteryPercentage! > 50 ? AppColors.success : AppColors.warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${bike.batteryPercentage}% (${bike.rangeKm} km)'),
                                      ],
                                    )
                                  : Text('Petrol (${bike.rangeKm} km range)'),
                            ),
                            DataCell(Text(CurrencyFormatter.format(bike.dailyRate))),
                            DataCell(Text('${bike.odometerKm} km')),
                          ],
                        );
                      }).toList(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Error: $e'),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double width;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BikeStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case BikeStatus.available:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        label = 'Available';
        break;
      case BikeStatus.reserved:
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
        label = 'Reserved';
        break;
      case BikeStatus.inUse:
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        label = 'In Use';
        break;
      case BikeStatus.maintenance:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        label = 'Maintenance';
        break;
      case BikeStatus.retired:
        bg = Colors.grey.withValues(alpha: 0.2);
        fg = Colors.grey;
        label = 'Retired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
