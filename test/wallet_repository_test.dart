import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/data/datasources/mock_data_source.dart';
import 'package:rental_subscription_platform/data/repositories/mock_wallet_repository.dart';
import 'package:rental_subscription_platform/domain/entities/wallet.dart';

void main() {
  late MockWalletRepository walletRepo;

  setUp(() {
    walletRepo = MockWalletRepository();
    // Reset seed wallet state before each test
    MockDataSource.userWallets['usr_demo_customer'] = Wallet(
      id: 'wal_demo_01',
      userId: 'usr_demo_customer',
      mainBalance: 450.0,
      bonusBalance: 100.0,
      totalSaved: 250.0,
      updatedAt: DateTime.now(),
    );
    MockDataSource.userWallets.remove('usr_new_friend');
    MockDataSource.userTransactions['usr_demo_customer'] = [
      WalletTransaction(
        id: 'tx_01',
        walletId: 'wal_demo_01',
        userId: 'usr_demo_customer',
        amount: 500.0,
        type: WalletTransactionType.refund,
        title: 'Security Deposit Refund',
        description: 'Automatic 100% deposit refund for completed trip BK-2026-0810',
        referenceId: 'BK-2026-0810',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  });

  group('VeloCash Wallet & Referral Engine Unit Tests', () {
    test('getWallet returns initial user balance and properties correctly', () async {
      final wallet = await walletRepo.getWallet('usr_demo_customer');

      expect(wallet.userId, equals('usr_demo_customer'));
      expect(wallet.mainBalance, equals(450.0));
      expect(wallet.bonusBalance, equals(100.0));
      expect(wallet.totalBalance, equals(550.0));
      expect(wallet.totalSaved, equals(250.0));
    });

    test('getTopUpPackages provides cashback bonus tiers', () async {
      final packages = await walletRepo.getTopUpPackages();

      expect(packages.length, greaterThanOrEqualTo(3));
      final p1000 = packages.firstWhere((p) => p.amount == 1000.0);
      expect(p1000.bonusAmount, equals(100.0));
      expect(p1000.totalCredited, equals(1100.0));
      expect(p1000.tag, contains('Most Popular'));
    });

    test('topUpWallet credits main amount plus cashback bonus to balance', () async {
      final initialWallet = await walletRepo.getWallet('usr_demo_customer');
      final initialMain = initialWallet.mainBalance;
      final initialBonus = initialWallet.bonusBalance;

      final updatedWallet = await walletRepo.topUpWallet(
        userId: 'usr_demo_customer',
        amount: 1000.0,
        bonusAmount: 100.0,
        paymentId: 'pay_test_topup_1',
      );

      expect(updatedWallet.mainBalance, equals(initialMain + 1000.0));
      expect(updatedWallet.bonusBalance, equals(initialBonus + 100.0));
      expect(updatedWallet.totalBalance, equals(initialWallet.totalBalance + 1100.0));

      final transactions = await walletRepo.getTransactions('usr_demo_customer');
      expect(transactions.any((t) => t.type == WalletTransactionType.credit && t.amount == 1100.0), isTrue);
    });

    test('debitWallet consumes bonus balance first before main cash balance', () async {
      // Current: Main ₹400, Bonus ₹150 (Total ₹550)
      // Debit ₹200: Bonus ₹150 consumed entirely, remaining ₹50 debited from Main (leaving ₹350 Main, ₹0 Bonus)
      final updated = await walletRepo.debitWallet(
        userId: 'usr_demo_customer',
        amount: 200.0,
        referenceId: 'VR-TEST-BOOKING',
        description: 'Test Ride Payment',
      );

      expect(updated.bonusBalance, equals(0.0));
      expect(updated.mainBalance, equals(350.0));
      expect(updated.totalBalance, equals(350.0));

      final transactions = await walletRepo.getTransactions('usr_demo_customer');
      final debitTx = transactions.firstWhere((t) => t.referenceId == 'VR-TEST-BOOKING');
      expect(debitTx.isPositive, isFalse);
      expect(debitTx.amount, equals(200.0));
    });

    test('debitWallet throws error when amount exceeds total balance', () async {
      // Total available is ₹550
      expect(
        () => walletRepo.debitWallet(
          userId: 'usr_demo_customer',
          amount: 10000.0,
          referenceId: 'VR-OVER-LIMIT',
          description: 'Excessive debit',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('creditDepositRefund credits amount to main cash balance and records transaction', () async {
      final initialWallet = await walletRepo.getWallet('usr_demo_customer');

      final updated = await walletRepo.creditDepositRefund(
        userId: 'usr_demo_customer',
        amount: 500.0,
        bookingId: 'VR-REFUND-99',
      );

      expect(updated.mainBalance, equals(initialWallet.mainBalance + 500.0));

      final transactions = await walletRepo.getTransactions('usr_demo_customer');
      final refundTx = transactions.firstWhere((t) => t.referenceId == 'VR-REFUND-99');
      expect(refundTx.type, equals(WalletTransactionType.refund));
      expect(refundTx.isPositive, isTrue);
      expect(refundTx.amount, equals(500.0));
    });

    test('getReferralInfo returns user referral code and referral stats', () async {
      final info = await walletRepo.getReferralInfo('usr_demo_customer');

      expect(info.referralCode, equals('VELO-BALA-482'));
      expect(info.rewardPerReferral, equals(100.0));
      expect(info.referralCount, greaterThanOrEqualTo(3));
      expect(info.totalEarned, equals(300.0));
    });

    test('redeemReferralCode rejects self-referral', () async {
      expect(
        () => walletRepo.redeemReferralCode(
          userId: 'usr_demo_customer',
          referralCode: 'VELO-BALA-482',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('redeemReferralCode awards bonus to both referee and referrer', () async {
      final initialReferrer = await walletRepo.getWallet('usr_demo_customer');
      final initialReferee = await walletRepo.getWallet('usr_new_friend');

      final success = await walletRepo.redeemReferralCode(
        userId: 'usr_new_friend',
        referralCode: 'VELO-BALA-482',
      );

      expect(success, isTrue);

      final updatedReferrer = await walletRepo.getWallet('usr_demo_customer');
      final updatedReferee = await walletRepo.getWallet('usr_new_friend');

      // Both should have received ₹100 bonus cash
      expect(updatedReferrer.bonusBalance, equals(initialReferrer.bonusBalance + 100.0));
      expect(updatedReferee.bonusBalance, equals(initialReferee.bonusBalance + 100.0));

      // Duplicate claiming by same user should throw or return false
      expect(
        () => walletRepo.redeemReferralCode(
          userId: 'usr_new_friend',
          referralCode: 'VELO-BALA-482',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
