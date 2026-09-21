import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/booking.dart';
import '../../../../services/telematics/telematics_service.dart';
import '../../../common/providers/repository_providers.dart';

class ActiveTripTelematicsCard extends ConsumerStatefulWidget {
  final Booking booking;
  final VoidCallback onTripCompleted;

  const ActiveTripTelematicsCard({
    super.key,
    required this.booking,
    required this.onTripCompleted,
  });

  @override
  ConsumerState<ActiveTripTelematicsCard> createState() => _ActiveTripTelematicsCardState();
}

class _ActiveTripTelematicsCardState extends ConsumerState<ActiveTripTelematicsCard> {
  bool _isLocking = false;

  @override
  void initState() {
    super.initState();
    // Start telematics session if not already running
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final telematics = ref.read(telematicsServiceProvider);
      if (telematics.currentState == null || telematics.currentState!.bookingId != widget.booking.id) {
        telematics.startSession(
          bookingId: widget.booking.id,
          bikeId: widget.booking.bikeId,
          bikeName: 'Smart Connected EV',
          initialBattery: 94.0,
        );
      }
    });
  }

  Future<void> _handleToggleLock() async {
    setState(() => _isLocking = true);
    final telematics = ref.read(telematicsServiceProvider);
    await telematics.toggleSmartLock();
    if (mounted) {
      setState(() => _isLocking = false);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final telematicsAsync = ref.watch(telematicsStreamProvider);
    final telematics = telematicsAsync.value ?? ref.read(telematicsServiceProvider).currentState;

    final battery = telematics?.batteryPercentage ?? 94.0;
    final speed = telematics?.speedKmph ?? 0.0;
    final distance = telematics?.distanceTraveledKm ?? 0.0;
    final duration = telematics?.tripDuration ?? Duration.zero;
    final lockState = telematics?.lockState ?? SmartLockState.locked;
    final isUnlocked = lockState == SmartLockState.unlocked;
    final range = telematics?.estimatedRangeRemainingKm ?? 108.0;

    final isInsideGeofence = telematics?.isWithinGeofence ?? true;

    Color batteryColor = AppColors.success;
    if (battery < 20) {
      batteryColor = AppColors.error;
    } else if (battery < 40) {
      batteryColor = AppColors.warning;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F766E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Active Trip HUD & Geofence Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: AppColors.secondaryLight, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LIVE EV TELEMATICS HUD',
                          style: TextStyle(
                            color: AppColors.secondaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'Trip #${widget.booking.bookingNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isInsideGeofence
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isInsideGeofence ? AppColors.success : AppColors.error,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isInsideGeofence ? Icons.security_rounded : Icons.warning_amber_rounded,
                        size: 13,
                        color: isInsideGeofence ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isInsideGeofence ? 'Hyderabad Safe Zone' : 'Geofence Warning',
                        style: TextStyle(
                          color: isInsideGeofence ? Colors.white : const Color(0xFFFCA5A5),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Telematics Telemetry Grid (Battery, Speed, Distance, Duration)
            Row(
              children: [
                // Battery Gauge
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Battery SoC', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            Icon(Icons.battery_charging_full_rounded, color: batteryColor, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$battery%',
                          style: TextStyle(
                            color: batteryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text('~$range km range', style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Live Speedometer
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Live Speed', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            Icon(Icons.speed_rounded, color: AppColors.secondaryLight, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$speed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text('km/h (IoT GPS)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Distance & Timer
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Distance', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$distance km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(_formatDuration(duration), style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Smart Lock Action Controls & Return Button
            Row(
              children: [
                // 1-Tap Smart Lock Toggle Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUnlocked ? const Color(0xFFDC2626) : AppColors.secondary,
                      foregroundColor: isUnlocked ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isLocking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(isUnlocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded, size: 20),
                    label: Text(
                      isUnlocked ? '🔒 Standby Lock EV' : '⚡ Keyless Unlock (Ignition ON)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _isLocking ? null : _handleToggleLock,
                  ),
                ),
                const SizedBox(width: 12),

                // Return Vehicle & End Trip Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white60, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text(
                      'Return & End',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () async {
                      ref.read(telematicsServiceProvider).stopSession();
                      await ref.read(bookingRepositoryProvider).recordReturn(
                        widget.booking.id,
                        5000 + distance.toInt(),
                        widget.booking.returnStationId,
                      );
                      widget.onTripCompleted();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
