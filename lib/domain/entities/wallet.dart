enum WalletTransactionType {
  credit,
  debit,
  refund,
  cashback,
  referralReward,
}

class Wallet {
  final String id;
  final String userId;
  final double mainBalance; // Real deposited cash & deposit refunds
  final double bonusBalance; // Promotional cashbacks & referral rewards
  final double totalSaved; // Lifetime savings via cashback & promos
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    this.mainBalance = 0.0,
    this.bonusBalance = 0.0,
    this.totalSaved = 0.0,
    required this.updatedAt,
  });

  double get totalBalance => mainBalance + bonusBalance;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'main_balance': mainBalance,
    'bonus_balance': bonusBalance,
    'total_saved': totalSaved,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    mainBalance: (json['main_balance'] as num?)?.toDouble() ?? 0.0,
    bonusBalance: (json['bonus_balance'] as num?)?.toDouble() ?? 0.0,
    totalSaved: (json['total_saved'] as num?)?.toDouble() ?? 0.0,
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

class WalletTransaction {
  final String id;
  final String walletId;
  final String userId;
  final double amount;
  final WalletTransactionType type;
  final String title;
  final String description;
  final String? referenceId; // bookingId, subscriptionId, paymentId
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.title,
    required this.description,
    this.referenceId,
    required this.createdAt,
  });

  bool get isPositive =>
      type == WalletTransactionType.credit ||
      type == WalletTransactionType.refund ||
      type == WalletTransactionType.cashback ||
      type == WalletTransactionType.referralReward;

  Map<String, dynamic> toJson() => {
    'id': id,
    'wallet_id': walletId,
    'user_id': userId,
    'amount': amount,
    'type': type.name,
    'title': title,
    'description': description,
    'reference_id': referenceId,
    'created_at': createdAt.toIso8601String(),
  };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
    id: json['id'] as String,
    walletId: json['wallet_id'] as String,
    userId: json['user_id'] as String,
    amount: (json['amount'] as num).toDouble(),
    type: WalletTransactionType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => WalletTransactionType.credit,
    ),
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    referenceId: json['reference_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class WalletTopUpPackage {
  final String id;
  final double amount;
  final double bonusAmount;
  final String? tag; // e.g. "Popular", "Super Saver"

  const WalletTopUpPackage({
    required this.id,
    required this.amount,
    this.bonusAmount = 0.0,
    this.tag,
  });

  double get totalCredited => amount + bonusAmount;
}

class ReferralInfo {
  final String userId;
  final String referralCode;
  final int referralCount;
  final double totalEarned;
  final double rewardPerReferral;

  const ReferralInfo({
    required this.userId,
    required this.referralCode,
    this.referralCount = 0,
    this.totalEarned = 0.0,
    this.rewardPerReferral = 100.0,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'referral_code': referralCode,
    'referral_count': referralCount,
    'total_earned': totalEarned,
    'reward_per_referral': rewardPerReferral,
  };

  factory ReferralInfo.fromJson(Map<String, dynamic> json) => ReferralInfo(
    userId: json['user_id'] as String,
    referralCode: json['referral_code'] as String,
    referralCount: json['referral_count'] as int? ?? 0,
    totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0.0,
    rewardPerReferral: (json['reward_per_referral'] as num?)?.toDouble() ?? 100.0,
  );
}
