import '../entities/wallet.dart';

abstract class WalletRepository {
  /// Fetch user wallet balances
  Future<Wallet> getWallet(String userId);

  /// Fetch user transaction history ledger
  Future<List<WalletTransaction>> getTransactions(String userId);

  /// Top-up wallet with real cash + promotional bonus cash
  Future<Wallet> topUpWallet({
    required String userId,
    required double amount,
    required double bonusAmount,
    required String paymentId,
  });

  /// Debit wallet balance to pay for rental booking or subscription
  Future<Wallet> debitWallet({
    required String userId,
    required double amount,
    required String referenceId,
    required String description,
  });

  /// Credit instant deposit refund directly to wallet
  Future<Wallet> creditDepositRefund({
    required String userId,
    required double amount,
    required String bookingId,
  });

  /// Get referral code & statistics for a user
  Future<ReferralInfo> getReferralInfo(String userId);

  /// Redeem a friend's referral code
  Future<bool> redeemReferralCode({
    required String userId,
    required String referralCode,
  });

  /// Get available top-up packages
  Future<List<WalletTopUpPackage>> getTopUpPackages();
}
