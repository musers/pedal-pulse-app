import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/mock_data_source.dart';

class SupabaseWalletRepository implements WalletRepository {
  final SupabaseClient _client;

  SupabaseWalletRepository(this._client);

  @override
  Future<Wallet> getWallet(String userId) async {
    final response = await _client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Create initial wallet with ₹50 welcome bonus
      final insert = await _client
          .from('wallets')
          .insert({
            'user_id': userId,
            'main_balance': 0.0,
            'bonus_balance': 50.0,
            'total_saved': 50.0,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Wallet.fromJson(insert);
    }

    return Wallet.fromJson(response);
  }

  @override
  Future<List<WalletTransaction>> getTransactions(String userId) async {
    final response = await _client
        .from('wallet_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => WalletTransaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Wallet> topUpWallet({
    required String userId,
    required double amount,
    required double bonusAmount,
    required String paymentId,
  }) async {
    final wallet = await getWallet(userId);

    final updated = await _client
        .from('wallets')
        .update({
          'main_balance': wallet.mainBalance + amount,
          'bonus_balance': wallet.bonusBalance + bonusAmount,
          'total_saved': wallet.totalSaved + bonusAmount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', wallet.id)
        .select()
        .single();

    // Log transaction
    await _client.from('wallet_transactions').insert({
      'wallet_id': wallet.id,
      'user_id': userId,
      'amount': amount + bonusAmount,
      'type': 'credit',
      'title': 'Wallet Top-Up via Razorpay',
      'description': bonusAmount > 0 ? 'Added ₹${amount.toInt()} + ₹${bonusAmount.toInt()} Bonus' : 'Added ₹${amount.toInt()}',
      'reference_id': paymentId,
      'created_at': DateTime.now().toIso8601String(),
    });

    return Wallet.fromJson(updated);
  }

  @override
  Future<Wallet> debitWallet({
    required String userId,
    required double amount,
    required String referenceId,
    required String description,
  }) async {
    final wallet = await getWallet(userId);
    if (wallet.totalBalance < amount) {
      throw Exception('Insufficient wallet balance');
    }

    double remaining = amount;
    double newBonus = wallet.bonusBalance;
    double newMain = wallet.mainBalance;

    if (newBonus >= remaining) {
      newBonus -= remaining;
      remaining = 0;
    } else {
      remaining -= newBonus;
      newBonus = 0;
      newMain -= remaining;
    }

    final updated = await _client
        .from('wallets')
        .update({
          'main_balance': newMain,
          'bonus_balance': newBonus,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', wallet.id)
        .select()
        .single();

    // Log transaction
    await _client.from('wallet_transactions').insert({
      'wallet_id': wallet.id,
      'user_id': userId,
      'amount': amount,
      'type': 'debit',
      'title': 'Ride Payment',
      'description': description,
      'reference_id': referenceId,
      'created_at': DateTime.now().toIso8601String(),
    });

    return Wallet.fromJson(updated);
  }

  @override
  Future<Wallet> creditDepositRefund({
    required String userId,
    required double amount,
    required String bookingId,
  }) async {
    final wallet = await getWallet(userId);

    final updated = await _client
        .from('wallets')
        .update({
          'main_balance': wallet.mainBalance + amount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', wallet.id)
        .select()
        .single();

    // Log transaction
    await _client.from('wallet_transactions').insert({
      'wallet_id': wallet.id,
      'user_id': userId,
      'amount': amount,
      'type': 'refund',
      'title': 'Instant Deposit Refund',
      'description': '100% security deposit release for booking $bookingId',
      'reference_id': bookingId,
      'created_at': DateTime.now().toIso8601String(),
    });

    return Wallet.fromJson(updated);
  }

  @override
  Future<ReferralInfo> getReferralInfo(String userId) async {
    final response = await _client
        .from('referrals')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      final code = 'VELO-${userId.substring(userId.length > 4 ? userId.length - 4 : 0).toUpperCase()}';
      final insert = await _client
          .from('referrals')
          .insert({
            'user_id': userId,
            'referral_code': code,
            'referral_count': 0,
            'total_earned': 0.0,
            'reward_per_referral': 100.0,
          })
          .select()
          .single();

      return ReferralInfo.fromJson(insert);
    }

    return ReferralInfo.fromJson(response);
  }

  @override
  Future<bool> redeemReferralCode({
    required String userId,
    required String referralCode,
  }) async {
    final cleanCode = referralCode.trim().toUpperCase();
    final res = await _client.rpc('redeem_referral_code', params: {
      'p_user_id': userId,
      'p_code': cleanCode,
    });
    return res as bool? ?? true;
  }

  @override
  Future<List<WalletTopUpPackage>> getTopUpPackages() async {
    return MockDataSource.topUpPackages;
  }
}
