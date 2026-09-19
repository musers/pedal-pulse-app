enum SubscriptionBillingCycle {
  weekly,
  monthly,
  quarterly,
}

enum UserSubscriptionStatus {
  active,
  paused,
  completed,
  cancelled,
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String tagline;
  final String vehicleType; // e.g. "Electric Smart Scooter", "Commuter Bike", "Premium Tourer"
  final String categoryId;
  final int durationDays;
  final SubscriptionBillingCycle billingCycle;
  final double price; // INR per cycle
  final double securityDeposit;
  final int dailyKmCap; // 0 for unlimited
  final bool isUnlimitedKm;
  final bool freeMaintenanceIncluded;
  final bool swappableBatteryAccess;
  final bool helmetIncluded;
  final bool doorstepDelivery;
  final List<String> highlights;
  final bool isPopular;
  final bool isActive;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.vehicleType,
    required this.categoryId,
    required this.durationDays,
    required this.billingCycle,
    required this.price,
    required this.securityDeposit,
    this.dailyKmCap = 80,
    this.isUnlimitedKm = false,
    this.freeMaintenanceIncluded = true,
    this.swappableBatteryAccess = true,
    this.helmetIncluded = true,
    this.doorstepDelivery = true,
    required this.highlights,
    this.isPopular = false,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagline': tagline,
    'vehicle_type': vehicleType,
    'category_id': categoryId,
    'duration_days': durationDays,
    'billing_cycle': billingCycle.name,
    'price': price,
    'security_deposit': securityDeposit,
    'daily_km_cap': dailyKmCap,
    'is_unlimited_km': isUnlimitedKm,
    'free_maintenance_included': freeMaintenanceIncluded,
    'swappable_battery_access': swappableBatteryAccess,
    'helmet_included': helmetIncluded,
    'doorstep_delivery': doorstepDelivery,
    'highlights': highlights,
    'is_popular': isPopular,
    'is_active': isActive,
  };

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
    id: json['id'] as String,
    name: json['name'] as String,
    tagline: json['tagline'] as String? ?? '',
    vehicleType: json['vehicle_type'] as String? ?? 'Electric Scooter',
    categoryId: json['category_id'] as String? ?? 'cat_ev_scooter',
    durationDays: json['duration_days'] as int? ?? 30,
    billingCycle: SubscriptionBillingCycle.values.firstWhere(
      (c) => c.name == json['billing_cycle'],
      orElse: () => SubscriptionBillingCycle.monthly,
    ),
    price: (json['price'] as num).toDouble(),
    securityDeposit: (json['security_deposit'] as num).toDouble(),
    dailyKmCap: json['daily_km_cap'] as int? ?? 80,
    isUnlimitedKm: json['is_unlimited_km'] as bool? ?? false,
    freeMaintenanceIncluded: json['free_maintenance_included'] as bool? ?? true,
    swappableBatteryAccess: json['swappable_battery_access'] as bool? ?? true,
    helmetIncluded: json['helmet_included'] as bool? ?? true,
    doorstepDelivery: json['doorstep_delivery'] as bool? ?? true,
    highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    isPopular: json['is_popular'] as bool? ?? false,
    isActive: json['is_active'] as bool? ?? true,
  );
}

class UserSubscription {
  final String id;
  final String subscriptionNumber;
  final String userId;
  final String planId;
  final String planName;
  final String? assignedBikeId;
  final String? assignedBikeName;
  final String pickupStationId;
  final DateTime startDate;
  final DateTime endDate;
  final double amountPaid;
  final double securityDeposit;
  final String? promoCodeUsed;
  final double discountApplied;
  final UserSubscriptionStatus status;
  final String depositStatus;
  final bool autoRenew;
  final DateTime createdAt;

  const UserSubscription({
    required this.id,
    required this.subscriptionNumber,
    required this.userId,
    required this.planId,
    required this.planName,
    this.assignedBikeId,
    this.assignedBikeName,
    required this.pickupStationId,
    required this.startDate,
    required this.endDate,
    required this.amountPaid,
    required this.securityDeposit,
    this.promoCodeUsed,
    this.discountApplied = 0.0,
    this.status = UserSubscriptionStatus.active,
    this.depositStatus = 'held',
    this.autoRenew = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subscription_number': subscriptionNumber,
    'user_id': userId,
    'plan_id': planId,
    'plan_name': planName,
    'assigned_bike_id': assignedBikeId,
    'assigned_bike_name': assignedBikeName,
    'pickup_station_id': pickupStationId,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'amount_paid': amountPaid,
    'security_deposit': securityDeposit,
    'promo_code_used': promoCodeUsed,
    'discount_applied': discountApplied,
    'status': status.name,
    'deposit_status': depositStatus,
    'auto_renew': autoRenew,
    'created_at': createdAt.toIso8601String(),
  };

  factory UserSubscription.fromJson(Map<String, dynamic> json) => UserSubscription(
    id: json['id'] as String,
    subscriptionNumber: json['subscription_number'] as String,
    userId: json['user_id'] as String,
    planId: json['plan_id'] as String,
    planName: json['plan_name'] as String,
    assignedBikeId: json['assigned_bike_id'] as String?,
    assignedBikeName: json['assigned_bike_name'] as String?,
    pickupStationId: json['pickup_station_id'] as String,
    startDate: DateTime.parse(json['start_date'] as String),
    endDate: DateTime.parse(json['end_date'] as String),
    amountPaid: (json['amount_paid'] as num).toDouble(),
    securityDeposit: (json['security_deposit'] as num).toDouble(),
    promoCodeUsed: json['promo_code_used'] as String?,
    discountApplied: (json['discount_applied'] as num?)?.toDouble() ?? 0.0,
    status: UserSubscriptionStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => UserSubscriptionStatus.active,
    ),
    depositStatus: json['deposit_status'] as String? ?? 'held',
    autoRenew: json['auto_renew'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
