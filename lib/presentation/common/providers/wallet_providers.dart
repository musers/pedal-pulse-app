import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/wallet.dart';
import 'auth_state_provider.dart';
import 'repository_providers.dart';

final userWalletFutureProvider = FutureProvider<Wallet?>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return Future.value(null);
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getWallet(user.id);
});

final walletTransactionsFutureProvider = FutureProvider<List<WalletTransaction>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return Future.value([]);
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getTransactions(user.id);
});

final userReferralInfoFutureProvider = FutureProvider<ReferralInfo?>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return Future.value(null);
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getReferralInfo(user.id);
});

final topUpPackagesFutureProvider = FutureProvider<List<WalletTopUpPackage>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getTopUpPackages();
});
