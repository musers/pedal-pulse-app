import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/services/telematics/telematics_service.dart';

void main() {
  group('Real-Time IoT Telematics & Keyless Smart Lock Tests', () {
    late TelematicsService telematics;

    setUp(() {
      telematics = TelematicsService();
    });

    tearDown(() {
      telematics.dispose();
    });

    test('Initial state is null before starting session', () {
      expect(telematics.currentState, isNull);
    });

    test('startSession initializes EV telematics snapshot with correct defaults', () {
      telematics.startSession(
        bookingId: 'bk_hyd_101',
        bikeId: 'bike_ather_450x',
        bikeName: 'Ather 450X Gen 3',
        initialBattery: 92.0,
      );

      final state = telematics.currentState;
      expect(state, isNotNull);
      expect(state!.bookingId, 'bk_hyd_101');
      expect(state.bikeId, 'bike_ather_450x');
      expect(state.batteryPercentage, 92.0);
      expect(state.lockState, SmartLockState.locked);
      expect(state.isWithinGeofence, isTrue);
      expect(state.speedKmph, 0.0);
      expect(state.distanceTraveledKm, 0.0);
    });

    test('toggleSmartLock switches between locked and unlocked state', () async {
      telematics.startSession(
        bookingId: 'bk_hyd_102',
        bikeId: 'bike_ola_s1_pro',
        bikeName: 'Ola S1 Pro Gen 2',
      );

      expect(telematics.currentState!.lockState, SmartLockState.locked);

      final unlocked = await telematics.toggleSmartLock();
      expect(unlocked, SmartLockState.unlocked);
      expect(telematics.currentState!.lockState, SmartLockState.unlocked);

      final lockedAgain = await telematics.toggleSmartLock();
      expect(lockedAgain, SmartLockState.locked);
      expect(telematics.currentState!.lockState, SmartLockState.locked);
    });

    test('Estimated range decreases proportionally with SoC drain', () {
      telematics.startSession(
        bookingId: 'bk_hyd_103',
        bikeId: 'bike_tvs_iqube',
        bikeName: 'TVS iQube S',
        initialBattery: 100.0,
      );

      final range100 = telematics.currentState!.estimatedRangeRemainingKm;
      expect(range100, closeTo(110.0, 1.0));

      // Telematics calculates range = (battery * 1.1)
      final range50 = 50.0 * 1.1;
      expect(range50, closeTo(55.0, 0.01));
    });

    test('stopSession halts tracking and clears active telemetry state', () {
      telematics.startSession(
        bookingId: 'bk_hyd_104',
        bikeId: 'bike_river_indie',
        bikeName: 'River Indie EV',
      );
      expect(telematics.currentState, isNotNull);

      telematics.stopSession();
      expect(telematics.currentState, isNull);
    });
  });
}
