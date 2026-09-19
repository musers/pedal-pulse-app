import '../../domain/entities/user_profile.dart';

abstract class AuthService {
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> sendOtp({required String phoneNumber});
  Future<UserProfile> verifyOtp({
    required String phoneNumber,
    required String otpToken,
  });
  Future<void> signOut();
  Future<UserProfile> updateProfile({
    String? fullName,
    String? email,
    String? drivingLicenseNumber,
    String? drivingLicenseDocUrl,
    KycStatus? kycStatus,
  });
}
