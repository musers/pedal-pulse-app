import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/mock_data_source.dart';

class MockWalletRepository implements WalletRepository {
  @override
  Future<Wallet> getWallet(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!MockDataSource.userWallets.containsKey(userId)) {
      MockDataSource.userWallets[userId] = Wallet(
        id: 'wal_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        mainBalance: 0.0,
        bonusBalance: 50.0, // Welcome signup bonus
        totalSaved: 50.0,
        updatedAt: DateTime.now(),
      );
      MockDataSource.userTransactions[userId] = [
        WalletTransaction(
          id: 'tx_init_${DateTime.now().millisecondsSinceEpoch}',
          walletId: MockDataSource.userWallets[userId]!.id,
          userId: userId,
          amount: 50.0,
          type: WalletTransactionType.cashback,
          title: 'Welcome Bonus',
          description: 'VeloRide welcome bonus credited to your wallet',
          createdAt: DateTime.now(),
        ),
      ];
    }
    return MockDataSource.userWallets[userId]!;
  }

  @override
  Future<List<WalletTransaction>> getTransactions(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return MockDataSource.userTransactions[userId] ?? [];
  }

  @override
  Future<Wallet> topUpWallet({
    required String userId,
    required double amount,
    required double bonusAmount,
    required String paymentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final current = await getWallet(userId);
    final updated = Wallet(
      id: current.id,
      userId: userId,
      mainBalance: current.mainBalance + amount,
      bonusBalance: current.bonusBalance + bonusAmount,
      totalSaved: current.totalSaved + bonusAmount,
      updatedAt: DateTime.now(),
    );

    MockDataSource.userWallets[userId] = updated;

    final txList = MockDataSource.userTransactions[userId] ?? [];
    txList.insert(
      0,
      WalletTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        walletId: current.id,
        userId: userId,
        amount: amount + bonusAmount,
        type: WalletTransactionType.credit,
        title: 'Wallet Top-Up via Razorpay',
        description: bonusAmount > 0
            ? 'Added ${amount.toInt()} + ${bonusAmount.toInt()} Bonus Cash'
            : 'Added ${amount.toInt()} to VeloCash',
        referenceId: paymentId,
        createdAt: DateTime.now(),
      ),
    );
    MockDataSource.userTransactions[userId] = txList;

    return updated;
  }

  @override
  Future<Wallet> debitWallet({
    required String userId,
    required double amount,
    required String referenceId,
    required String description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final current = await getWallet(userId);
    if (current.totalBalance < amount) {
      throw Exception('Insufficient VeloCash balance (Available: ₹${current.totalBalance.toInt()}).');
    }

    // Deduct from bonus balance first, then main balance
    double remainingToDeduct = amount;
    double newBonus = current.bonusBalance;
    double newMain = current.mainBalance;

    if (newBonus >= remainingToDeduct) {
      newBonus -= remainingToDeduct;
      remainingToDeduct = 0;
    } else {
      remainingToDeduct -= newBonus;
      newBonus = 0;
      newMain -= remainingToDeduct;
    }

    final updated = Wallet(
      id: current.id,
      userId: userId,
      mainBalance: newMain,
      bonusBalance: newBonus,
      totalSaved: current.totalSaved,
      updatedAt: DateTime.now(),
    );

    MockDataSource.userWallets[userId] = updated;

    final txList = MockDataSource.userTransactions[userId] ?? [];
    txList.insert(
      0,
      WalletTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        walletId: current.id,
        userId: userId,
        amount: amount,
        type: WalletTransactionType.debit,
        title: 'Ride / Pass Payment',
        description: description,
        referenceId: referenceId,
        createdAt: DateTime.now(),
      ),
    );
    MockDataSource.userTransactions[userId] = txList;

    return updated;
  }

  @override
  Future<Wallet> creditDepositRefund({
    required String userId,
    required double amount,
    required String bookingId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final current = await getWallet(userId);
    final updated = Wallet(
      id: current.id,
      userId: userId,
      mainBalance: current.mainBalance + amount,
      bonusBalance: current.bonusBalance,
      totalSaved: current.totalSaved,
      updatedAt: DateTime.now(),
    );

    MockDataSource.userWallets[userId] = updated;

    final txList = MockDataSource.userTransactions[userId] ?? [];
    txList.insert(
      0,
      WalletTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        walletId: current.id,
        userId: userId,
        amount: amount,
        type: WalletTransactionType.refund,
        title: 'Instant Deposit Refund',
        description: 'Instant 100% security deposit release for booking $bookingId',
        referenceId: bookingId,
        createdAt: DateTime.now(),
      ),
    );
    MockDataSource.userTransactions[userId] = txList;

    return updated;
  }

  @override
  Future<ReferralInfo> getReferralInfo(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!MockDataSource.userReferrals.containsKey(userId)) {
      final code = 'VELO-${userId.substring(userId.length > 4 ? userId.length - 4 : 0).toUpperCase()}-RIDE';
      MockDataSource.userReferrals[userId] = ReferralInfo(
        userId: userId,
        referralCode: code,
        referralCount: 0,
        totalEarned: 0.0,
      );
    }
    return MockDataSource.userReferrals[userId]!;
  }

  @override
  Future<bool> redeemReferralCode({
    required String userId,
    required String referralCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cleanCode = referralCode.trim().toUpperCase();

    // Check if code belongs to another user
    final referrerEntry = MockDataSource.userReferrals.entries.cast<MapEntry<String, ReferralInfo>?>().firstWhere(
      (e) => e?.value.referralCode == cleanCode && e?.key != userId,
      orElse: () => null,
    );

    if (referrerEntry == null) {
      throw Exception('Invalid or self-referral code "$cleanCode".');
    }

    // Check if user has already claimed a referral bonus
    final existingRefereeTx = MockDataSource.userTransactions[userId] ?? [];
    if (existingRefereeTx.any((t) => t.type == WalletTransactionType.referralReward)) {
      throw Exception('You have already redeemed a referral welcome bonus.');
    }

    // Reward referee with ₹100 bonus cash
    final refereeWallet = await getWallet(userId);
    MockDataSource.userWallets[userId] = Wallet(
      id: refereeWallet.id,
      userId: userId,
      mainBalance: refereeWallet.mainBalance,
      bonusBalance: refereeWallet.bonusBalance + 100.0,
      totalSaved: refereeWallet.totalSaved + 100.0,
      updatedAt: DateTime.now(),
    );

    final refereeTx = MockDataSource.userTransactions[userId] ?? [];
    refereeTx.insert(
      0,
      WalletTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        walletId: refereeWallet.id,
        userId: userId,
        amount: 100.0,
        type: WalletTransactionType.referralReward,
        title: 'Referral Welcome Bonus',
        description: 'Joined via referral code $cleanCode',
        referenceId: cleanCode,
        createdAt: DateTime.now(),
      ),
    );
    MockDataSource.userTransactions[userId] = refereeTx;

    // Update referrer stats & bonus wallet balance
    final referrer = referrerEntry.value;
    MockDataSource.userReferrals[referrer.userId] = ReferralInfo(
      userId: referrer.userId,
      referralCode: referrer.referralCode,
      referralCount: referrer.referralCount + 1,
      totalEarned: referrer.totalEarned + 100.0,
    );

    final referrerWallet = await getWallet(referrer.userId);
    MockDataSource.userWallets[referrer.userId] = Wallet(
      id: referrerWallet.id,
      userId: referrer.userId,
      mainBalance: referrerWallet.mainBalance,
      bonusBalance: referrerWallet.bonusBalance + 100.0,
      totalSaved: referrerWallet.totalSaved + 100.0,
      updatedAt: DateTime.now(),
    );

    final referrerTx = MockDataSource.userTransactions[referrer.userId] ?? [];
    referrerTx.insert(
      0,
      WalletTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch + 1}',
        walletId: referrerWallet.id,
        userId: referrer.userId,
        amount: 100.0,
        type: WalletTransactionType.referralReward,
        title: 'Referral Friend Bonus',
        description: 'Friend joined using your code $cleanCode',
        referenceId: cleanCode,
        createdAt: DateTime.now(),
      ),
    );
    MockDataSource.userTransactions[referrer.userId] = referrerTx;

    return true;
  }

  @override
  Future<List<WalletTopUpPackage>> getTopUpPackages() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return MockDataSource.topUpPackages;
  }
}
