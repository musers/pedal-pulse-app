import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/auth/mock_auth_service.dart';
import '../../../services/auth/supabase_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final client = SupabaseConfig.client;
  if (client != null) {
    return SupabaseAuthService(client);
  }
  return MockAuthService();
});

final authStreamProvider = StreamProvider<UserProfile?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

class AuthController extends Notifier<AsyncValue<UserProfile?>> {
  @override
  AsyncValue<UserProfile?> build() {
    final authService = ref.watch(authServiceProvider);
    
    // Listen to changes from the service
    final subscription = authService.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    return AsyncValue.data(authService.currentUser);
  }

  Future<void> sendOtp(String phoneNumber) async {
    final authService = ref.read(authServiceProvider);
    state = const AsyncValue.loading();
    try {
      await authService.sendOtp(phoneNumber: phoneNumber);
      state = AsyncValue.data(authService.currentUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<UserProfile> verifyOtp(String phoneNumber, String otpToken) async {
    final authService = ref.read(authServiceProvider);
    state = const AsyncValue.loading();
    try {
      final user = await authService.verifyOtp(
        phoneNumber: phoneNumber,
        otpToken: otpToken,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<UserProfile> updateProfile({
    String? fullName,
    String? email,
    String? drivingLicenseNumber,
    String? drivingLicenseDocUrl,
    KycStatus? kycStatus,
  }) async {
    final authService = ref.read(authServiceProvider);
    try {
      final updated = await authService.updateProfile(
        fullName: fullName,
        email: email,
        drivingLicenseNumber: drivingLicenseNumber,
        drivingLicenseDocUrl: drivingLicenseDocUrl,
        kycStatus: kycStatus,
      );
      state = AsyncValue.data(updated);
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    state = const AsyncValue.loading();
    try {
      await authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<UserProfile?>>(AuthController.new);
