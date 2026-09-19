import '../entities/promo_code.dart';

abstract class PromoRepository {
  /// Fetch all active & valid promo codes (for customer offer listings)
  Future<List<PromoCode>> getActivePromos();

  /// Fetch all promo codes including expired & disabled (for Admin Coupon Desk)
  Future<List<PromoCode>> getAllPromos();

  /// Validate a coupon code and calculate applicable discount
  Future<PromoValidationResult> validatePromo({
    required String code,
    required double orderAmount,
    required PromoApplicableType orderType,
  });

  /// Create a new time-bound promo code (Admin)
  Future<PromoCode> createPromo(PromoCode promo);

  /// Toggle active/disabled status of a coupon (Admin)
  Future<void> togglePromoStatus(String promoId, bool isActive);

  /// Delete a coupon code (Admin)
  Future<void> deletePromo(String promoId);

  /// Increment usage counter when a coupon is successfully redeemed
  Future<void> recordPromoRedemption(String promoCode);
}
