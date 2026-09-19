import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/data/repositories/mock_promo_repository.dart';
import 'package:rental_subscription_platform/domain/entities/promo_code.dart';

void main() {
  late MockPromoRepository promoRepo;

  setUp(() {
    promoRepo = MockPromoRepository();
  });

  group('Dynamic Promo Engine Unit Tests', () {
    test('calculateDiscount computes percentage discount capped at maxDiscountAmount', () {
      final promo = PromoCode(
        id: 'test_1',
        code: 'TEST20',
        description: '20% off up to 200',
        discountType: DiscountType.percentage,
        discountValue: 20.0,
        minOrderAmount: 300.0,
        maxDiscountAmount: 200.0,
        validFrom: DateTime.now().subtract(const Duration(days: 1)),
        validUntil: DateTime.now().add(const Duration(days: 30)),
      );

      // Order ₹500: 20% is ₹100 (below cap ₹200) -> ₹100
      expect(promo.calculateDiscount(500.0), equals(100.0));

      // Order ₹2000: 20% is ₹400 (exceeds cap ₹200) -> capped at ₹200
      expect(promo.calculateDiscount(2000.0), equals(200.0));

      // Order below minimum (₹250 < ₹300) -> 0
      expect(promo.calculateDiscount(250.0), equals(0.0));
    });

    test('calculateDiscount computes flat discount correctly', () {
      final promo = PromoCode(
        id: 'test_2',
        code: 'FLAT100',
        description: 'Flat ₹100 off',
        discountType: DiscountType.flat,
        discountValue: 100.0,
        minOrderAmount: 500.0,
        validFrom: DateTime.now().subtract(const Duration(days: 1)),
        validUntil: DateTime.now().add(const Duration(days: 30)),
      );

      expect(promo.calculateDiscount(600.0), equals(100.0));
      expect(promo.calculateDiscount(400.0), equals(0.0)); // below minimum
    });

    test('validatePromo succeeds for valid coupon START50', () async {
      final result = await promoRepo.validatePromo(
        code: 'START50',
        orderAmount: 350.0,
        orderType: PromoApplicableType.rental,
      );

      expect(result.isValid, isTrue);
      expect(result.discountAmount, equals(50.0));
      expect(result.promoCode?.code, equals('START50'));
    });

    test('validatePromo rejects expired coupon EXPIRED20', () async {
      final result = await promoRepo.validatePromo(
        code: 'EXPIRED20',
        orderAmount: 500.0,
        orderType: PromoApplicableType.all,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('expired'));
    });

    test('validatePromo rejects coupon when order amount is below minimum', () async {
      final result = await promoRepo.validatePromo(
        code: 'MONTHLY500', // Requires min ₹5,000
        orderAmount: 2000.0,
        orderType: PromoApplicableType.subscription,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Minimum order value'));
    });

    test('validatePromo rejects coupon with mismatched applicable type', () async {
      // BLRCOMMUTE is for rentals only
      final result = await promoRepo.validatePromo(
        code: 'BLRCOMMUTE',
        orderAmount: 6000.0,
        orderType: PromoApplicableType.subscription,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('only applicable'));
    });

    test('createPromo adds a new time-bound coupon and prevents duplicate codes', () async {
      final newPromo = PromoCode(
        id: '',
        code: 'DIWALI30',
        description: 'Diwali Festive Special',
        discountType: DiscountType.percentage,
        discountValue: 30.0,
        minOrderAmount: 400.0,
        maxDiscountAmount: 300.0,
        validFrom: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 15)),
        usageLimit: 200,
        applicableType: PromoApplicableType.all,
      );

      final created = await promoRepo.createPromo(newPromo);
      expect(created.code, equals('DIWALI30'));

      // Duplicate creation should throw
      expect(() => promoRepo.createPromo(newPromo), throwsA(isA<Exception>()));
    });
  });
}
