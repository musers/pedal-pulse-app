import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/subscription_repository.dart';

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  final SupabaseClient _client;

  SupabaseSubscriptionRepository(this._client);

  @override
  Future<List<SubscriptionPlan>> getActivePlans() async {
    final response = await _client
        .from('subscription_plans')
        .select()
        .eq('is_active', true)
        .order('price', ascending: true);

    return (response as List<dynamic>)
        .map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>))
        .toList();
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
    final now = DateTime.now();
    final endDate = now.add(Duration(days: durationDays));
    final subNumber = 'SUB-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final insertData = {
      'subscription_number': subNumber,
      'user_id': userId,
      'plan_id': planId,
      'plan_name': planName,
      'pickup_station_id': pickupStationId,
      'start_date': now.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'amount_paid': amountPaid,
      'security_deposit': securityDeposit,
      'promo_code_used': promoCodeUsed,
      'discount_applied': discountApplied,
      'status': 'active',
      'deposit_status': 'held',
      'auto_renew': autoRenew,
      'created_at': now.toIso8601String(),
    };

    final response = await _client
        .from('user_subscriptions')
        .insert(insertData)
        .select()
        .single();

    return UserSubscription.fromJson(response);
  }

  @override
  Future<List<UserSubscription>> getUserSubscriptions(String userId) async {
    final response = await _client
        .from('user_subscriptions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => UserSubscription.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<UserSubscription>> getAllSubscriptions() async {
    final response = await _client
        .from('user_subscriptions')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => UserSubscription.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UserSubscription> updateSubscriptionStatus({
    required String subscriptionId,
    required UserSubscriptionStatus status,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.name,
    };
    if (status == UserSubscriptionStatus.completed) {
      updateData['deposit_status'] = 'refunded';
    }
    if (status == UserSubscriptionStatus.cancelled) {
      updateData['auto_renew'] = false;
    }

    final response = await _client
        .from('user_subscriptions')
        .update(updateData)
        .eq('id', subscriptionId)
        .select()
        .single();

    return UserSubscription.fromJson(response);
  }

  @override
  Future<UserSubscription> assignBikeToSubscription({
    required String subscriptionId,
    required String bikeId,
    required String bikeName,
  }) async {
    final response = await _client
        .from('user_subscriptions')
        .update({
          'assigned_bike_id': bikeId,
          'assigned_bike_name': bikeName,
        })
        .eq('id', subscriptionId)
        .select()
        .single();

    return UserSubscription.fromJson(response);
  }
}
