import 'dart:async';
import '../../domain/entities/user_profile.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  UserProfile? _currentUser;
  final _authStateController = StreamController<UserProfile?>.broadcast();

  // Test accounts for quick demo & testing
  static final UserProfile defaultVerifiedUser = UserProfile(
    id: 'usr_demo_customer_01',
    phoneNumber: '+919876500000',
    fullName: 'Bala Gangadhar',
    email: 'bala@veloride.in',
    role: UserRole.customer,
    kycStatus: KycStatus.verified,
    drivingLicenseNumber: 'KA-01-2022-0049210',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  static final UserProfile adminUser = UserProfile(
    id: 'usr_demo_admin_01',
    phoneNumber: '+919999900001',
    fullName: 'Admin Manager',
    email: 'admin@veloride.in',
    role: UserRole.admin,
    kycStatus: KycStatus.verified,
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
  );

  MockAuthService({bool startAuthenticated = true}) {
    if (startAuthenticated) {
      _currentUser = defaultVerifiedUser;
    }
  }

  @override
  Stream<UserProfile?> get authStateChanges async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<void> sendOtp({required String phoneNumber}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<void> sendEmailOtp({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<UserProfile> verifyEmailOtp({
    required String email,
    required String otpToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (otpToken.length != 6) {
      throw Exception('Invalid OTP. Please enter a valid 6-digit OTP code.');
    }

    if (email.contains('admin')) {
      _currentUser = adminUser;
    } else if (email.contains('bala')) {
      _currentUser = defaultVerifiedUser;
    } else {
      _currentUser = UserProfile(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: '',
        fullName: email.split('@').first,
        email: email,
        role: UserRole.customer,
        kycStatus: KycStatus.notSubmitted,
        createdAt: DateTime.now(),
      );
    }

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserProfile> verifyOtp({
    required String phoneNumber,
    required String otpToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (otpToken.length != 6) {
      throw Exception('Invalid OTP. Please enter a valid 6-digit OTP code.');
    }

    if (phoneNumber.contains('9999900001')) {
      _currentUser = adminUser;
    } else if (phoneNumber.contains('9876500000')) {
      _currentUser = defaultVerifiedUser;
    } else {
      // New user registration
      _currentUser = UserProfile(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        phoneNumber: phoneNumber,
        fullName: 'New Customer',
        role: UserRole.customer,
        kycStatus: KycStatus.notSubmitted,
        createdAt: DateTime.now(),
      );
    }

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<UserProfile> updateProfile({
    String? fullName,
    String? email,
    String? drivingLicenseNumber,
    String? drivingLicenseDocUrl,
    KycStatus? kycStatus,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentUser == null) {
      throw Exception('User is not authenticated.');
    }

    _currentUser = _currentUser!.copyWith(
      fullName: fullName ?? _currentUser!.fullName,
      email: email ?? _currentUser!.email,
      drivingLicenseNumber: drivingLicenseNumber ?? _currentUser!.drivingLicenseNumber,
      drivingLicenseDocUrl: drivingLicenseDocUrl ?? _currentUser!.drivingLicenseDocUrl,
      kycStatus: kycStatus ??
          (drivingLicenseNumber != null && drivingLicenseNumber.isNotEmpty
              ? KycStatus.pendingReview
              : _currentUser!.kycStatus),
    );

    _authStateController.add(_currentUser);
    return _currentUser!;
  }

  void dispose() {
    _authStateController.close();
  }
}
