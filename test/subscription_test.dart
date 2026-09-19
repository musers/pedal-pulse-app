import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/data/repositories/mock_subscription_repository.dart';
import 'package:rental_subscription_platform/domain/entities/subscription_plan.dart';

void main() {
  late MockSubscriptionRepository subRepo;

  setUp(() {
    subRepo = MockSubscriptionRepository();
  });

  group('Subscription Repository & Pass Management Unit Tests', () {
    test('getActivePlans returns pre-seeded weekly and monthly passes', () async {
      final plans = await subRepo.getActivePlans();
      expect(plans.isNotEmpty, isTrue);
      expect(plans.any((p) => p.billingCycle == SubscriptionBillingCycle.weekly), isTrue);
      expect(plans.any((p) => p.billingCycle == SubscriptionBillingCycle.monthly), isTrue);
    });

    test('createSubscription creates valid contract with deposit and period', () async {
      final sub = await subRepo.createSubscription(
        userId: 'usr_test_subscriber',
        planId: 'plan_weekly_ev',
        planName: 'Weekly City Commute Pass',
        pickupStationId: 'st_koramangala',
        durationDays: 7,
        amountPaid: 1899.0,
        securityDeposit: 1499.0,
        promoCodeUsed: 'START50',
        discountApplied: 50.0,
        autoRenew: true,
      );

      expect(sub.subscriptionNumber, startsWith('SUB-2026-'));
      expect(sub.status, equals(UserSubscriptionStatus.active));
      expect(sub.depositStatus, equals('held'));
      expect(sub.amountPaid, equals(1899.0));
      expect(sub.autoRenew, isTrue);
      expect(sub.endDate.difference(sub.startDate).inDays, equals(7));
    });

    test('updateSubscriptionStatus updates status and marks deposit refunded upon completion', () async {
      final sub = await subRepo.createSubscription(
        userId: 'usr_test_subscriber_2',
        planId: 'plan_monthly_pro',
        planName: 'Monthly Pro Rider',
        pickupStationId: 'st_indiranagar',
        durationDays: 30,
        amountPaid: 6499.0,
        securityDeposit: 1999.0,
      );

      // Pause pass
      final paused = await subRepo.updateSubscriptionStatus(
        subscriptionId: sub.id,
        status: UserSubscriptionStatus.paused,
      );
      expect(paused.status, equals(UserSubscriptionStatus.paused));

      // Complete pass & release deposit
      final completed = await subRepo.updateSubscriptionStatus(
        subscriptionId: sub.id,
        status: UserSubscriptionStatus.completed,
      );
      expect(completed.status, equals(UserSubscriptionStatus.completed));
      expect(completed.depositStatus, equals('refunded'));
    });

    test('assignBikeToSubscription updates assigned vehicle details', () async {
      final sub = await subRepo.createSubscription(
        userId: 'usr_test_subscriber_3',
        planId: 'plan_monthly_pro',
        planName: 'Monthly Pro Rider',
        pickupStationId: 'st_indiranagar',
        durationDays: 30,
        amountPaid: 6499.0,
        securityDeposit: 1999.0,
      );

      final updated = await subRepo.assignBikeToSubscription(
        subscriptionId: sub.id,
        bikeId: 'bike_002',
        bikeName: 'Ola S1 Pro (KA 03 HM 8820)',
      );

      expect(updated.assignedBikeId, equals('bike_002'));
      expect(updated.assignedBikeName, contains('Ola S1 Pro'));
    });
  });
}
