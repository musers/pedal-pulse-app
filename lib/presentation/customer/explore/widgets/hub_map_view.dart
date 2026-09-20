import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/station.dart';
import '../../../../services/maps/map_service.dart';
import '../../../common/providers/repository_providers.dart';

class HubMapView extends ConsumerStatefulWidget {
  final List<Station> stations;
  final String? selectedStationId;
  final ValueChanged<String?> onStationSelected;

  const HubMapView({
    super.key,
    required this.stations,
    required this.selectedStationId,
    required this.onStationSelected,
  });

  @override
  ConsumerState<HubMapView> createState() => _HubMapViewState();
}

class _HubMapViewState extends ConsumerState<HubMapView> {
  GeoLocation? _userLocation;
  final Map<String, double> _stationDistances = {};
  final TextEditingController _searchController = TextEditingController();
  List<GeoLocation> _searchResults = [];
  bool _isSearching = false;

  final List<String> _quickLocations = [
    'HITEC City',
    'Miyapur Metro',
    'Gachibowli',
    'Madhapur',
    'Financial District',
    'KPHB',
  ];

  @override
  void initState() {
    super.initState();
    _loadLocationAndDistances();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationAndDistances([GeoLocation? customLocation]) async {
    final mapService = ref.read(mapServiceProvider);
    final userLoc = customLocation ?? await mapService.getCurrentLocation();
    if (!mounted) return;

    final distances = <String, double>{};
    for (final st in widget.stations) {
      final stLoc = GeoLocation(latitude: st.latitude, longitude: st.longitude);
      final dist = await mapService.calculateDistanceKm(userLoc, stLoc);
      distances[st.id] = dist;
    }

    if (mounted) {
      setState(() {
        _userLocation = userLoc;
        _stationDistances.clear();
        _stationDistances.addAll(distances);
      });
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final mapService = ref.read(mapServiceProvider);
    final results = await mapService.searchPlaces(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectLocation(GeoLocation loc) {
    setState(() {
      _userLocation = loc;
      _searchController.text = loc.address ?? 'Selected Location';
      _searchResults = [];
    });
    _loadLocationAndDistances(loc);
  }

  Future<void> _openGoogleMapsNavigation(Station station) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Google Places Search & Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search location in Hyderabad (e.g. Gachibowli, Cyber Towers)...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearch('');
                            _loadLocationAndDistances();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.lightSurfaceCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.lightBorder),
                  ),
                ),
                onChanged: (val) => _handleSearch(val),
              ),

              // Search Autocomplete Dropdown List
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final item = _searchResults[idx];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_rounded, color: AppColors.primary, size: 18),
                        title: Text(item.address ?? 'Hyderabad Location', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text('${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        onTap: () => _selectLocation(item),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 10),

              // Quick Location Filter Chips
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickLocations.length,
                  itemBuilder: (context, idx) {
                    final place = _quickLocations[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                        label: Text(place, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        backgroundColor: AppColors.lightSurfaceCard,
                        side: const BorderSide(color: AppColors.lightBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          _searchController.text = place;
                          _handleSearch(place);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Interactive Map Visualizer Canvas
        Container(
          height: 230,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B192C),
                Color(0xFF1E3E62),
                Color(0xFF000000),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Stylized Grid & Hyderabad Roads
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HyderabadMapPainter(),
                  ),
                ),

                // Map Header Badge
                Positioned(
                  top: 12,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_rounded, color: AppColors.primaryLight, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _userLocation?.address != null && _userLocation!.address!.isNotEmpty
                              ? 'Near: ${_userLocation!.address!.split(',')[0]}'
                              : 'Hyderabad Smart EV Grid',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                // Live GPS indicator
                if (_userLocation != null)
                  Positioned(
                    left: 100,
                    top: 130,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Your Location', style: TextStyle(color: Colors.white, fontSize: 9)),
                        ),
                      ],
                    ),
                  ),

                // Smart EV Hub Pins
                _buildStationPin(
                  station: widget.stations.isNotEmpty ? widget.stations[0] : null,
                  left: 170,
                  top: 60,
                ),
                _buildStationPin(
                  station: widget.stations.length > 1 ? widget.stations[1] : null,
                  left: 230,
                  top: 110,
                ),

                // Reset filter button
                if (widget.selectedStationId != null)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimaryLight,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.clear, size: 14),
                      label: const Text('All Hubs', style: TextStyle(fontSize: 12)),
                      onPressed: () => widget.onStationSelected(null),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 3. Station Cards with Google Maps Navigation Link
        SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.stations.length,
            itemBuilder: (context, index) {
              final station = widget.stations[index];
              final isSelected = station.id == widget.selectedStationId;
              final distance = _stationDistances[station.id];

              return Container(
                width: 295,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  elevation: isSelected ? 3 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.lightBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      widget.onStationSelected(isSelected ? null : station.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  station.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (distance != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.directions_bike_rounded, size: 12, color: AppColors.primary),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$distance km',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            station.address,
                            style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.electric_moped_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${station.availableBikesCount} EVs Ready',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.directions_rounded, size: 18, color: AppColors.primary),
                                    tooltip: 'Open in Google Maps',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _openGoogleMapsNavigation(station),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isSelected ? '✓ Filtered' : 'Filter Fleet',
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStationPin({
    required Station? station,
    required double left,
    required double top,
  }) {
    if (station == null) return const SizedBox();
    final isSelected = station.id == widget.selectedStationId;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          widget.onStationSelected(isSelected ? null : station.id);
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondary : AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.electric_moped_rounded,
                    size: 13,
                    color: isSelected ? Colors.black87 : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${station.availableBikesCount}',
                    style: TextStyle(
                      color: isSelected ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              station.name.split(' ')[0],
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _HyderabadMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 28) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 28) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Outer Ring Road (ORR) & Miyapur-HITEC Corridor
    final roadPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.25)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(0, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.2, size.width, size.height * 0.7);
    canvas.drawPath(path1, roadPaint);

    final path2 = Path()
      ..moveTo(size.width * 0.25, 0)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.5, size.width * 0.75, size.height);
    canvas.drawPath(path2, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
