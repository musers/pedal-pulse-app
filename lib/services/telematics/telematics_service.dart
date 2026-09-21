import 'dart:async';
import 'dart:math';

enum SmartLockState {
  locked,
  unlocking,
  unlocked,
  locking,
}

class TelematicsState {
  final String bookingId;
  final String bikeId;
  final String bikeName;
  final double batteryPercentage;
  final double speedKmph;
  final double distanceTraveledKm;
  final Duration tripDuration;
  final SmartLockState lockState;
  final bool isWithinGeofence;
  final double currentLatitude;
  final double currentLongitude;
  final String currentLocationName;
  final double estimatedRangeRemainingKm;

  const TelematicsState({
    required this.bookingId,
    required this.bikeId,
    required this.bikeName,
    required this.batteryPercentage,
    required this.speedKmph,
    required this.distanceTraveledKm,
    required this.tripDuration,
    required this.lockState,
    required this.isWithinGeofence,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.currentLocationName,
    required this.estimatedRangeRemainingKm,
  });

  TelematicsState copyWith({
    String? bookingId,
    String? bikeId,
    String? bikeName,
    double? batteryPercentage,
    double? speedKmph,
    double? distanceTraveledKm,
    Duration? tripDuration,
    SmartLockState? lockState,
    bool? isWithinGeofence,
    double? currentLatitude,
    double? currentLongitude,
    String? currentLocationName,
    double? estimatedRangeRemainingKm,
  }) {
    return TelematicsState(
      bookingId: bookingId ?? this.bookingId,
      bikeId: bikeId ?? this.bikeId,
      bikeName: bikeName ?? this.bikeName,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      speedKmph: speedKmph ?? this.speedKmph,
      distanceTraveledKm: distanceTraveledKm ?? this.distanceTraveledKm,
      tripDuration: tripDuration ?? this.tripDuration,
      lockState: lockState ?? this.lockState,
      isWithinGeofence: isWithinGeofence ?? this.isWithinGeofence,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentLocationName: currentLocationName ?? this.currentLocationName,
      estimatedRangeRemainingKm: estimatedRangeRemainingKm ?? this.estimatedRangeRemainingKm,
    );
  }
}

class TelematicsService {
  final _telematicsController = StreamController<TelematicsState>.broadcast();
  TelematicsState? _currentState;
  Timer? _simulationTimer;
  DateTime? _tripStartTime;
  final Random _random = Random();

  // Hyderabad Operational Geofence Boundaries (Miyapur, Kondapur, Gachibowli, HITEC City, KPHB)
  static const double hydCenterLat = 17.4646;
  static const double hydCenterLng = 78.3667;
  static const double maxGeofenceRadiusKm = 25.0;

  Stream<TelematicsState> get telematicsStream => _telematicsController.stream;
  TelematicsState? get currentState => _currentState;

  void startSession({
    required String bookingId,
    required String bikeId,
    required String bikeName,
    double initialBattery = 95.0,
  }) {
    _tripStartTime = DateTime.now();
    _simulationTimer?.cancel();

    _currentState = TelematicsState(
      bookingId: bookingId,
      bikeId: bikeId,
      bikeName: bikeName,
      batteryPercentage: initialBattery,
      speedKmph: 0.0,
      distanceTraveledKm: 0.0,
      tripDuration: Duration.zero,
      lockState: SmartLockState.locked,
      isWithinGeofence: true,
      currentLatitude: 17.4646,
      currentLongitude: 78.3667,
      currentLocationName: 'Kondapur Smart EV Hub',
      estimatedRangeRemainingKm: (initialBattery * 1.1).roundToDouble(),
    );

    _telematicsController.add(_currentState!);

    // Real-time telemetry tick every 2 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentState == null) return;

      final isUnlocked = _currentState!.lockState == SmartLockState.unlocked;
      final elapsed = DateTime.now().difference(_tripStartTime!);

      // Calculate dynamic speed and distance when riding
      double newSpeed = 0.0;
      double newDistance = _currentState!.distanceTraveledKm;
      double newBattery = _currentState!.batteryPercentage;

      if (isUnlocked) {
        // Speed fluctuates realistically between 28 - 46 km/h
        newSpeed = 28.0 + _random.nextDouble() * 18.0;
        // Distance increases by speed * 2 seconds
        newDistance += (newSpeed / 3600.0) * 2.0;
        // Battery drains proportionally (~0.05% every 2 seconds when throttle is active)
        newBattery = max(5.0, newBattery - 0.04 - (_random.nextDouble() * 0.02));
      } else {
        newSpeed = 0.0;
      }

      // Check geofence
      final isInside = checkGeofence(_currentState!.currentLatitude, _currentState!.currentLongitude);

      _currentState = _currentState!.copyWith(
        speedKmph: double.parse(newSpeed.toStringAsFixed(1)),
        distanceTraveledKm: double.parse(newDistance.toStringAsFixed(2)),
        batteryPercentage: double.parse(newBattery.toStringAsFixed(1)),
        tripDuration: elapsed,
        isWithinGeofence: isInside,
        estimatedRangeRemainingKm: double.parse((newBattery * 1.15).toStringAsFixed(1)),
        currentLocationName: isUnlocked ? 'En-route HITEC City Corridor' : 'Parked & Standby',
      );

      _telematicsController.add(_currentState!);
    });
  }

  Future<SmartLockState> toggleSmartLock() async {
    if (_currentState == null) return SmartLockState.locked;

    if (_currentState!.lockState == SmartLockState.locked) {
      // Unlocking sequence
      _currentState = _currentState!.copyWith(lockState: SmartLockState.unlocking);
      _telematicsController.add(_currentState!);
      await Future.delayed(const Duration(milliseconds: 900));

      _currentState = _currentState!.copyWith(lockState: SmartLockState.unlocked);
      _telematicsController.add(_currentState!);
      return SmartLockState.unlocked;
    } else {
      // Locking sequence
      _currentState = _currentState!.copyWith(lockState: SmartLockState.locking);
      _telematicsController.add(_currentState!);
      await Future.delayed(const Duration(milliseconds: 900));

      _currentState = _currentState!.copyWith(lockState: SmartLockState.locked, speedKmph: 0.0);
      _telematicsController.add(_currentState!);
      return SmartLockState.locked;
    }
  }

  bool checkGeofence(double lat, double lng) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat - hydCenterLat) * (pi / 180.0);
    final dLon = (lng - hydCenterLng) * (pi / 180.0);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(hydCenterLat * pi / 180.0) * cos(lat * pi / 180.0);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadiusKm * c;

    return distance <= maxGeofenceRadiusKm;
  }

  void stopSession() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _currentState = null;
  }

  void dispose() {
    _simulationTimer?.cancel();
    _telematicsController.close();
  }
}
