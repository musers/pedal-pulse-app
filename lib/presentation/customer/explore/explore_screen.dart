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
import 'widgets/hub_map_view.dart';

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

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String query) => state = query;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class IsMapViewNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void setMap(bool value) => state = value;
}

final isMapViewProvider =
    NotifierProvider<IsMapViewNotifier, bool>(IsMapViewNotifier.new);

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
  final search = ref.watch(searchQueryProvider).toLowerCase();

  return repo.getBikes(categoryId: categoryId, stationId: stationId).then((bikes) {
    if (search.isEmpty) return bikes;
    return bikes.where((b) =>
      b.name.toLowerCase().contains(search) ||
      b.brand.toLowerCase().contains(search) ||
      b.model.toLowerCase().contains(search)
    ).toList();
  });
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
    final isMapView = ref.watch(isMapViewProvider);

    return Scaffold(
      appBar: !isDesktop
          ? AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
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
                  tooltip: isMapView ? 'Switch to Fleet List' : 'View Hubs on Map',
                  icon: Icon(
                    isMapView ? Icons.format_list_bulleted_rounded : Icons.map_outlined,
                    color: isMapView ? AppColors.secondary : AppColors.primary,
                  ),
                  onPressed: () => ref.read(isMapViewProvider.notifier).toggle(),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // Desktop / Web Hero Showcase Banner
          if (isDesktop)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.secondaryLight.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              '⚡ BENGALURU SMART MOBILITY',
                              style: TextStyle(
                                color: AppColors.secondaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Rent Premium Two-Wheelers\nHourly, Daily or Monthly.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Top EV Scooters & Highway Cruisers with instant Two-Wheeler DL verification and keyless hub pickup.',
                            style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 14),
                          ),
                          const SizedBox(height: 18),
                          // Key Feature Pills
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: const [
                              _HeroBadge(icon: Icons.electric_bolt_rounded, label: '100% Charged EVs'),
                              _HeroBadge(icon: Icons.verified_user_rounded, label: 'Refundable Deposit Guarantee'),
                              _HeroBadge(icon: Icons.speed_rounded, label: 'Instant QR Handover'),
                              _HeroBadge(icon: Icons.shield_rounded, label: 'Comprehensive Insurance'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Quick Action Box on the Hero Banner
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_city_rounded, color: AppColors.secondaryLight, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '4 Central Hubs Live',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pick up at Indiranagar, Koramangala, HSR Layout, or Whitefield. Return at any hub.',
                              style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.black,
                                minimumSize: const Size.fromHeight(42),
                              ),
                              icon: Icon(
                                isMapView ? Icons.format_list_bulleted_rounded : Icons.map_outlined,
                                size: 18,
                              ),
                              label: Text(
                                isMapView ? 'Switch to Fleet Grid' : 'Explore Hubs on Map',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () => ref.read(isMapViewProvider.notifier).toggle(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Interactive Hub Map Visualizer
          if (isMapView)
            SliverToBoxAdapter(
              child: stationsAsync.when(
                data: (stations) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 8),
                  child: HubMapView(
                    stations: stations,
                    selectedStationId: selectedStation,
                    onStationSelected: (id) =>
                        ref.read(selectedStationProvider.notifier).select(id),
                  ),
                ),
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (e, s) => const SizedBox(),
              ),
            ),

          // Station & Search Controls Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 8),
              child: Row(
                children: [
                  // Station Filter Dropdown
                  Expanded(
                    flex: isDesktop ? 2 : 3,
                    child: stationsAsync.when(
                      data: (stations) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: selectedStation,
                            isExpanded: true,
                            hint: const Row(
                              children: [
                                Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Text('All Pickup Hubs', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text('All Pickup Hubs (Bengaluru)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  ],
                                ),
                              ),
                              ...stations.map((st) => DropdownMenuItem(
                                value: st.id,
                                child: Text('${st.name} (${st.availableBikesCount} bikes)', style: const TextStyle(fontSize: 14)),
                              )),
                            ],
                            onChanged: (val) {
                              ref.read(selectedStationProvider.notifier).select(val);
                            },
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(height: 48),
                      error: (e, s) => const SizedBox(),
                    ),
                  ),

                  if (isDesktop) ...[
                    const SizedBox(width: 16),
                    // Live Search Field for Desktop
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: TextField(
                          onChanged: (val) => ref.read(searchQueryProvider.notifier).updateQuery(val),
                          decoration: const InputDecoration(
                            hintText: 'Search by model (e.g. Ather, Hunter, Activa)...',
                            prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondaryLight),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Categories Horizontal Chips
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              data: (categories) => SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
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
                          fontSize: 13,
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
                            fontSize: 13,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              loading: () => const SizedBox(height: 44),
              error: (e, s) => const SizedBox(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Bikes Grid
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
                          'No vehicles found in this category or hub',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Try clearing your search or picking "All Pickup Hubs".',
                          style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : (ResponsiveLayout.isTablet(context) ? 2 : 1),
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
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

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondaryLight, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _BikeCard extends StatefulWidget {
  final Bike bike;

  const _BikeCard({required this.bike});

  @override
  State<_BikeCard> createState() => _BikeCardState();
}

class _BikeCardState extends State<_BikeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bike = widget.bike;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? AppColors.primaryLight : AppColors.lightBorder,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/bike/${bike.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Image with Badges
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
                    // Gradient overlay at bottom of image
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.cardOverlayGradient,
                        ),
                      ),
                    ),
                    // Battery / Range Tag (Top-Left)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bike.batteryPercentage != null) ...[
                              const Icon(Icons.bolt_rounded, size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                '${bike.batteryPercentage}%',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                            ] else ...[
                              const Icon(Icons.local_gas_station_rounded, size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              '${bike.rangeKm} km range',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Availability Status Pill (Top-Right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: bike.isAvailable ? AppColors.success : AppColors.warning,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (bike.isAvailable ? AppColors.success : AppColors.warning).withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          bike.isAvailable ? 'Available' : 'Reserved',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    // Feature Tag on Bottom Image Edge
                    Positioned(
                      bottom: 8,
                      left: 12,
                      child: Text(
                        '${bike.brand} • ${bike.model}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Details & Pricing Section
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            bike.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${CurrencyFormatter.format(bike.hourlyRate)}/hr',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'or ${CurrencyFormatter.format(bike.dailyRate)}/day',
                              style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightSurfaceCard,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bike.registrationNumber,
                            style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _isHovered ? 'Book Now →' : 'View Details',
                          style: TextStyle(
                            color: _isHovered ? AppColors.primary : AppColors.textSecondaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
}
