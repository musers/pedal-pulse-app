import 'package:intl/intl.dart';
import '../../domain/entities/promo_code.dart';
import '../../domain/repositories/promo_repository.dart';
import '../datasources/mock_data_source.dart';

class MockPromoRepository implements PromoRepository {
  @override
  Future<List<PromoCode>> getActivePromos() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return MockDataSource.promoCodes.where((p) => p.isCurrentlyValid).toList();
  }

  @override
  Future<List<PromoCode>> getAllPromos() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(MockDataSource.promoCodes);
  }

  @override
  Future<PromoValidationResult> validatePromo({
    required String code,
    required double orderAmount,
    required PromoApplicableType orderType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final cleanCode = code.trim().toUpperCase();

    final promo = MockDataSource.promoCodes.cast<PromoCode?>().firstWhere(
      (p) => p?.code == cleanCode,
      orElse: () => null,
    );

    if (promo == null) {
      return PromoValidationResult.error('Invalid coupon code "$cleanCode". Please verify.');
    }

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
      return PromoValidationResult.error('Coupon "$cleanCode" has reached its maximum redemption limit.');
    }

    if (promo.applicableType != PromoApplicableType.all && promo.applicableType != orderType) {
      final typeLabel = promo.applicableType == PromoApplicableType.subscription
          ? 'long-term subscriptions'
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
    await Future.delayed(const Duration(milliseconds: 250));
    // Check for duplicate code
    final exists = MockDataSource.promoCodes.any((p) => p.code == promo.code.toUpperCase());
    if (exists) {
      throw Exception('Coupon code "${promo.code.toUpperCase()}" already exists.');
    }

    final newPromo = PromoCode(
      id: promo.id.isEmpty ? 'promo_${DateTime.now().millisecondsSinceEpoch}' : promo.id,
      code: promo.code.trim().toUpperCase(),
      description: promo.description,
      discountType: promo.discountType,
      discountValue: promo.discountValue,
      minOrderAmount: promo.minOrderAmount,
      maxDiscountAmount: promo.maxDiscountAmount,
      validFrom: promo.validFrom,
      validUntil: promo.validUntil,
      usageLimit: promo.usageLimit,
      usedCount: 0,
      applicableType: promo.applicableType,
      isActive: promo.isActive,
    );

    MockDataSource.promoCodes.insert(0, newPromo);
    return newPromo;
  }

  @override
  Future<void> togglePromoStatus(String promoId, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = MockDataSource.promoCodes.indexWhere((p) => p.id == promoId);
    if (index != -1) {
      final cur = MockDataSource.promoCodes[index];
      MockDataSource.promoCodes[index] = PromoCode(
        id: cur.id,
        code: cur.code,
        description: cur.description,
        discountType: cur.discountType,
        discountValue: cur.discountValue,
        minOrderAmount: cur.minOrderAmount,
        maxDiscountAmount: cur.maxDiscountAmount,
        validFrom: cur.validFrom,
        validUntil: cur.validUntil,
        usageLimit: cur.usageLimit,
        usedCount: cur.usedCount,
        applicableType: cur.applicableType,
        isActive: isActive,
      );
    }
  }

  @override
  Future<void> deletePromo(String promoId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    MockDataSource.promoCodes.removeWhere((p) => p.id == promoId);
  }

  @override
  Future<void> recordPromoRedemption(String promoCode) async {
    final index = MockDataSource.promoCodes.indexWhere((p) => p.code == promoCode.toUpperCase());
    if (index != -1) {
      final cur = MockDataSource.promoCodes[index];
      MockDataSource.promoCodes[index] = PromoCode(
        id: cur.id,
        code: cur.code,
        description: cur.description,
        discountType: cur.discountType,
        discountValue: cur.discountValue,
        minOrderAmount: cur.minOrderAmount,
        maxDiscountAmount: cur.maxDiscountAmount,
        validFrom: cur.validFrom,
        validUntil: cur.validUntil,
        usageLimit: cur.usageLimit,
        usedCount: cur.usedCount + 1,
        applicableType: cur.applicableType,
        isActive: cur.isActive,
      );
    }
  }
}
