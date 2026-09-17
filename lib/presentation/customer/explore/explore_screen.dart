import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../domain/entities/bike.dart';
import '../../../domain/entities/bike_category.dart';
import '../../../domain/entities/station.dart';
import '../../common/providers/repository_providers.dart';

class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? categoryId) => state = categoryId;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String?>(SelectedCategoryNotifier.new);

class SelectedStationNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? stationId) => state = stationId;
}

final selectedStationProvider =
    NotifierProvider<SelectedStationNotifier, String?>(SelectedStationNotifier.new);

final categoriesFutureProvider = FutureProvider<List<BikeCategory>>((ref) {
  final repo = ref.watch(bikeRepositoryProvider);
  return repo.getCategories();
});

final stationsFutureProvider = FutureProvider<List<Station>>((ref) {
  final repo = ref.watch(stationRepositoryProvider);
  return repo.getStations();
});

final bikesFutureProvider = FutureProvider<List<Bike>>((ref) {
  final repo = ref.watch(bikeRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final stationId = ref.watch(selectedStationProvider);
  return repo.getBikes(categoryId: categoryId, stationId: stationId);
});

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesFutureProvider);
    final stationsAsync = ref.watch(stationsFutureProvider);
    final bikesAsync = ref.watch(bikesFutureProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedStation = ref.watch(selectedStationProvider);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VeloRide India',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                stationsAsync.when(
                  data: (stations) {
                    final current = stations.firstWhere(
                      (s) => s.id == selectedStation,
                      orElse: () => stations.first,
                    );
                    return Text(
                      '${current.city} • ${current.name.split(" ")[0]} Hub',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    );
                  },
                  loading: () => const Text('Locating hubs...', style: TextStyle(fontSize: 12)),
                  error: (e, s) => const Text('Bengaluru', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Station Selector Banner
          SliverToBoxAdapter(
            child: stationsAsync.when(
              data: (stations) => Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.primaryLight.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: selectedStation,
                          hint: const Text(
                            'All Pickup Stations',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Bengaluru Pickup Hubs', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            ...stations.map((st) => DropdownMenuItem(
                              value: st.id,
                              child: Text('${st.name} (${st.availableBikesCount} bikes)'),
                            )),
                          ],
                          onChanged: (val) {
                            ref.read(selectedStationProvider.notifier).select(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 60),
              error: (e, s) => const SizedBox(),
            ),
          ),

          // Categories Horizontal Chips
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              data: (categories) => SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selectedCategory == null,
                        label: const Text('All Fleet'),
                        onSelected: (_) => ref.read(selectedCategoryProvider.notifier).select(null),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selectedCategory == null ? Colors.white : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...categories.map((cat) {
                      final isSelected = selectedCategory == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          avatar: cat.fuelType == FuelType.electric
                              ? Icon(Icons.bolt, size: 16, color: isSelected ? Colors.white : AppColors.success)
                              : Icon(Icons.local_gas_station, size: 16, color: isSelected ? Colors.white : AppColors.secondary),
                          label: Text(cat.name),
                          onSelected: (_) {
                            ref.read(selectedCategoryProvider.notifier).select(isSelected ? null : cat.id);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 48),
              error: (e, s) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Bikes Grid / List
          bikesAsync.when(
            data: (bikes) {
              if (bikes.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.two_wheeler_outlined, size: 64, color: AppColors.textSecondaryLight),
                        SizedBox(height: 12),
                        Text(
                          'No bikes available in this filter',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : (ResponsiveLayout.isTablet(context) ? 2 : 1),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 1.05 : 1.15,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bike = bikes[index];
                      return _BikeCard(bike: bike);
                    },
                    childCount: bikes.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, s) => SliverFillRemaining(
              child: Center(child: Text('Error loading fleet: $err')),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _BikeCard extends StatelessWidget {
  final Bike bike;

  const _BikeCard({required this.bike});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/bike/${bike.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bike Image with Badges
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    bike.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.lightSurfaceCard,
                      child: const Center(
                        child: Icon(Icons.electric_moped, size: 48, color: AppColors.primary),
                      ),
                    ),
                  ),
                  // Battery / Range Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (bike.batteryPercentage != null) ...[
                            const Icon(Icons.bolt, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              '${bike.batteryPercentage}%',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${bike.rangeKm} km range',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: bike.isAvailable ? AppColors.success : AppColors.warning,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        bike.isAvailable ? 'Available' : 'Reserved',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bike Details Section
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bike.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${CurrencyFormatter.format(bike.hourlyRate)}/hr',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${bike.brand} • ${bike.registrationNumber}',
                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'or ${CurrencyFormatter.format(bike.dailyRate)}/day',
                        style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
