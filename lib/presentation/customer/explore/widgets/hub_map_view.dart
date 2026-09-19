import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLocationAndDistances();
  }

  Future<void> _loadLocationAndDistances() async {
    final mapService = ref.read(mapServiceProvider);
    final userLoc = await mapService.getCurrentLocation();
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
        _stationDistances.addAll(distances);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simulated Interactive Map Canvas
        Container(
          height: 240,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
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
                // Stylized Grid Lines
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),

                // City Watermark / Label
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.near_me_rounded, color: AppColors.primaryLight, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Bengaluru Mobility Grid • Live Hubs',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                // User Location Dot
                if (_userLocation != null)
                  Positioned(
                    left: 90,
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
                          child: const Text('You are here', style: TextStyle(color: Colors.white, fontSize: 9)),
                        ),
                      ],
                    ),
                  ),

                // Hub Pins
                _buildStationPin(
                  station: widget.stations.isNotEmpty ? widget.stations[0] : null,
                  left: 140,
                  top: 100,
                ),
                _buildStationPin(
                  station: widget.stations.length > 1 ? widget.stations[1] : null,
                  left: 200,
                  top: 60,
                ),
                _buildStationPin(
                  station: widget.stations.length > 2 ? widget.stations[2] : null,
                  left: 70,
                  top: 160,
                ),
                _buildStationPin(
                  station: widget.stations.length > 3 ? widget.stations[3] : null,
                  left: 260,
                  top: 80,
                ),

                // Reset filter button if selected
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
                      label: const Text('View All Hubs', style: TextStyle(fontSize: 12)),
                      onPressed: () => widget.onStationSelected(null),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Station Cards Carousel / List
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.stations.length,
            itemBuilder: (context, index) {
              final station = widget.stations[index];
              final isSelected = station.id == widget.selectedStationId;
              final distance = _stationDistances[station.id];

              return Container(
                width: 280,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$distance km',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
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
                                  const Icon(Icons.two_wheeler_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${station.availableBikesCount} Available',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ],
                              ),
                              Text(
                                isSelected ? '✓ Selected' : 'Tap to Filter',
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Road Lines
    final roadPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.15)
      ..strokeWidth = 3.0;

    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.6), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.7, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
