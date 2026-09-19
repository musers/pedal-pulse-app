import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/promo_code.dart';
import '../../domain/repositories/promo_repository.dart';

class SupabasePromoRepository implements PromoRepository {
  final SupabaseClient _client;

  SupabasePromoRepository(this._client);

  @override
  Future<List<PromoCode>> getActivePromos() async {
    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from('promo_codes')
        .select()
        .eq('is_active', true)
        .lte('valid_from', now)
        .gte('valid_until', now)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => PromoCode.fromJson(json as Map<String, dynamic>))
        .where((p) => !p.isUsageExhausted)
        .toList();
  }

  @override
  Future<List<PromoCode>> getAllPromos() async {
    final response = await _client
        .from('promo_codes')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => PromoCode.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PromoValidationResult> validatePromo({
    required String code,
    required double orderAmount,
    required PromoApplicableType orderType,
  }) async {
    final cleanCode = code.trim().toUpperCase();

    final response = await _client
        .from('promo_codes')
        .select()
        .eq('code', cleanCode)
        .maybeSingle();

    if (response == null) {
      return PromoValidationResult.error('Invalid coupon code "$cleanCode". Please check and try again.');
    }

    final promo = PromoCode.fromJson(response);

    if (!promo.isActive) {
      return PromoValidationResult.error('Coupon code "$cleanCode" is currently disabled.');
    }

    final now = DateTime.now();
    if (now.isBefore(promo.validFrom)) {
      final startStr = DateFormat('dd MMM yyyy').format(promo.validFrom);
      return PromoValidationResult.error('Coupon "$cleanCode" is valid from $startStr.');
    }

    if (promo.isExpired) {
      final expStr = DateFormat('dd MMM yyyy, hh:mm a').format(promo.validUntil);
      return PromoValidationResult.error('Coupon "$cleanCode" expired on $expStr.');
    }

    if (promo.isUsageExhausted) {
      return PromoValidationResult.error('Coupon "$cleanCode" has reached its maximum redemptions.');
    }

    if (promo.applicableType != PromoApplicableType.all && promo.applicableType != orderType) {
      final typeLabel = promo.applicableType == PromoApplicableType.subscription
          ? 'subscriptions'
          : 'hourly/daily rentals';
      return PromoValidationResult.error('Coupon "$cleanCode" is only applicable for $typeLabel.');
    }

    if (orderAmount < promo.minOrderAmount) {
      return PromoValidationResult.error(
        'Minimum order value of ₹${promo.minOrderAmount.toInt()} required for coupon "$cleanCode".',
      );
    }

    final discount = promo.calculateDiscount(orderAmount);
    return PromoValidationResult.success(
      promoCode: promo,
      discountAmount: discount,
    );
  }

  @override
  Future<PromoCode> createPromo(PromoCode promo) async {
    final insertData = promo.toJson()..remove('id');
    final response = await _client
        .from('promo_codes')
        .insert(insertData)
        .select()
        .single();

    return PromoCode.fromJson(response);
  }

  @override
  Future<void> togglePromoStatus(String promoId, bool isActive) async {
    await _client
        .from('promo_codes')
        .update({'is_active': isActive})
        .eq('id', promoId);
  }

  @override
  Future<void> deletePromo(String promoId) async {
    await _client
        .from('promo_codes')
        .delete()
        .eq('id', promoId);
  }

  @override
  Future<void> recordPromoRedemption(String promoCode) async {
    await _client.rpc('increment_promo_usage', params: {'p_code': promoCode.toUpperCase()});
  }
}
