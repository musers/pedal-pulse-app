import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/mock_data_source.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<SubscriptionPlan>> getActivePlans() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return MockDataSource.subscriptionPlans.where((p) => p.isActive).toList();
  }

  @override
  Future<UserSubscription> createSubscription({
    required String userId,
    required String planId,
    required String planName,
    required String pickupStationId,
    required int durationDays,
    required double amountPaid,
    required double securityDeposit,
    String? promoCodeUsed,
    double discountApplied = 0.0,
    bool autoRenew = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final randomSuffix = (1000 + MockDataSource.userSubscriptions.length + 1).toString();

    final subscription = UserSubscription(
      id: 'sub_${now.millisecondsSinceEpoch}',
      subscriptionNumber: 'SUB-2026-$randomSuffix',
      userId: userId,
      planId: planId,
      planName: planName,
      pickupStationId: pickupStationId,
      startDate: now,
      endDate: now.add(Duration(days: durationDays)),
      amountPaid: amountPaid,
      securityDeposit: securityDeposit,
      promoCodeUsed: promoCodeUsed,
      discountApplied: discountApplied,
      status: UserSubscriptionStatus.active,
      depositStatus: 'held',
      autoRenew: autoRenew,
      createdAt: now,
    );

    MockDataSource.userSubscriptions.insert(0, subscription);
    return subscription;
  }

  @override
  Future<List<UserSubscription>> getUserSubscriptions(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return MockDataSource.userSubscriptions
        .where((s) => s.userId == userId)
        .toList();
  }

  @override
  Future<List<UserSubscription>> getAllSubscriptions() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(MockDataSource.userSubscriptions);
  }

  @override
  Future<UserSubscription> updateSubscriptionStatus({
    required String subscriptionId,
    required UserSubscriptionStatus status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = MockDataSource.userSubscriptions.indexWhere((s) => s.id == subscriptionId);
    if (index == -1) {
      throw Exception('Subscription not found: $subscriptionId');
    }

    final current = MockDataSource.userSubscriptions[index];
    final updated = UserSubscription(
      id: current.id,
      subscriptionNumber: current.subscriptionNumber,
      userId: current.userId,
      planId: current.planId,
      planName: current.planName,
      assignedBikeId: current.assignedBikeId,
      assignedBikeName: current.assignedBikeName,
      pickupStationId: current.pickupStationId,
      startDate: current.startDate,
      endDate: current.endDate,
      amountPaid: current.amountPaid,
      securityDeposit: current.securityDeposit,
      promoCodeUsed: current.promoCodeUsed,
      discountApplied: current.discountApplied,
      status: status,
      depositStatus: status == UserSubscriptionStatus.completed ? 'refunded' : current.depositStatus,
      autoRenew: status == UserSubscriptionStatus.cancelled ? false : current.autoRenew,
      createdAt: current.createdAt,
    );

    MockDataSource.userSubscriptions[index] = updated;
    return updated;
  }

  @override
  Future<UserSubscription> assignBikeToSubscription({
    required String subscriptionId,
    required String bikeId,
    required String bikeName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = MockDataSource.userSubscriptions.indexWhere((s) => s.id == subscriptionId);
    if (index == -1) {
      throw Exception('Subscription not found: $subscriptionId');
    }

    final current = MockDataSource.userSubscriptions[index];
    final updated = UserSubscription(
      id: current.id,
      subscriptionNumber: current.subscriptionNumber,
      userId: current.userId,
      planId: current.planId,
      planName: current.planName,
      assignedBikeId: bikeId,
      assignedBikeName: bikeName,
      pickupStationId: current.pickupStationId,
      startDate: current.startDate,
      endDate: current.endDate,
      amountPaid: current.amountPaid,
      securityDeposit: current.securityDeposit,
      promoCodeUsed: current.promoCodeUsed,
      discountApplied: current.discountApplied,
      status: current.status,
      depositStatus: current.depositStatus,
      autoRenew: current.autoRenew,
      createdAt: current.createdAt,
    );

    MockDataSource.userSubscriptions[index] = updated;
    return updated;
  }
}
