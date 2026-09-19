enum DiscountType {
  percentage,
  flat,
}

enum PromoApplicableType {
  all,
  rental,
  subscription,
}

class PromoCode {
  final String id;
  final String code; // Uppercase code (e.g. START50, BLRCOMMUTE)
  final String description;
  final DiscountType discountType;
  final double discountValue; // e.g. 20 (for 20%) or 100 (for ₹100 flat)
  final double minOrderAmount; // e.g. 300
  final double? maxDiscountAmount; // e.g. 250 (cap for percentage discounts)
  final DateTime validFrom;
  final DateTime validUntil; // Time-bound expiration!
  final int usageLimit; // Total allowed redemptions (0 for unlimited)
  final int usedCount;
  final PromoApplicableType applicableType;
  final bool isActive;

  const PromoCode({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0.0,
    this.maxDiscountAmount,
    required this.validFrom,
    required this.validUntil,
    this.usageLimit = 0,
    this.usedCount = 0,
    this.applicableType = PromoApplicableType.all,
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(validUntil);
  bool get isStarted => DateTime.now().isAfter(validFrom);
  bool get isUsageExhausted => usageLimit > 0 && usedCount >= usageLimit;
  bool get isCurrentlyValid => isActive && !isExpired && isStarted && !isUsageExhausted;

  /// Calculate the discount for a given base order amount
  double calculateDiscount(double orderAmount) {
    if (orderAmount < minOrderAmount) return 0.0;

    double discount = 0.0;
    if (discountType == DiscountType.percentage) {
      discount = (orderAmount * (discountValue / 100));
      if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
        discount = maxDiscountAmount!;
      }
    } else {
      discount = discountValue;
    }

    // Discount cannot exceed order amount
    return discount > orderAmount ? orderAmount : discount;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'description': description,
    'discount_type': discountType.name,
    'discount_value': discountValue,
    'min_order_amount': minOrderAmount,
    'max_discount_amount': maxDiscountAmount,
    'valid_from': validFrom.toIso8601String(),
    'valid_until': validUntil.toIso8601String(),
    'usage_limit': usageLimit,
    'used_count': usedCount,
    'applicable_type': applicableType.name,
    'is_active': isActive,
  };

  factory PromoCode.fromJson(Map<String, dynamic> json) => PromoCode(
    id: json['id'] as String,
    code: json['code'] as String,
    description: json['description'] as String? ?? '',
    discountType: DiscountType.values.firstWhere(
      (d) => d.name == json['discount_type'],
      orElse: () => DiscountType.percentage,
    ),
    discountValue: (json['discount_value'] as num).toDouble(),
    minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
    maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
    validFrom: DateTime.parse(json['valid_from'] as String),
    validUntil: DateTime.parse(json['valid_until'] as String),
    usageLimit: json['usage_limit'] as int? ?? 0,
    usedCount: json['used_count'] as int? ?? 0,
    applicableType: PromoApplicableType.values.firstWhere(
      (a) => a.name == json['applicable_type'],
      orElse: () => PromoApplicableType.all,
    ),
    isActive: json['is_active'] as bool? ?? true,
  );
}

class PromoValidationResult {
  final bool isValid;
  final double discountAmount;
  final String? errorMessage;
  final PromoCode? promoCode;

  const PromoValidationResult({
    required this.isValid,
    this.discountAmount = 0.0,
    this.errorMessage,
    this.promoCode,
  });

  factory PromoValidationResult.success({
    required PromoCode promoCode,
    required double discountAmount,
  }) => PromoValidationResult(
    isValid: true,
    discountAmount: discountAmount,
    promoCode: promoCode,
  );

  factory PromoValidationResult.error(String message) => PromoValidationResult(
    isValid: false,
    errorMessage: message,
  );
}
