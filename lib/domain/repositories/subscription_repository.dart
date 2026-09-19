import '../entities/subscription_plan.dart';

abstract class SubscriptionRepository {
  /// Fetch all active subscription plans available for users
  Future<List<SubscriptionPlan>> getActivePlans();

  /// Create a new user subscription
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
  });

  /// Get subscriptions for a specific user
  Future<List<UserSubscription>> getUserSubscriptions(String userId);

  /// Get all subscriptions across the system (for admin operations)
  Future<List<UserSubscription>> getAllSubscriptions();

  /// Pause, resume, or cancel a subscription
  Future<UserSubscription> updateSubscriptionStatus({
    required String subscriptionId,
    required UserSubscriptionStatus status,
  });

  /// Assign or reassign a physical bike to an active subscription (Admin)
  Future<UserSubscription> assignBikeToSubscription({
    required String subscriptionId,
    required String bikeId,
    required String bikeName,
  });
}
