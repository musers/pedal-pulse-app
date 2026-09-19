import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/domain/entities/user_profile.dart';
import 'package:rental_subscription_platform/services/auth/mock_auth_service.dart';

void main() {
  group('MockAuthService Unit Tests', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService(startAuthenticated: false);
    });

    tearDown(() {
      authService.dispose();
    });

    test('starts unauthenticated when configured', () {
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);
    });

    test('sendOtp completes without error', () async {
      await expectLater(
        authService.sendOtp(phoneNumber: '+919876500000'),
        completes,
      );
    });

    test('verifyOtp logs in default verified user', () async {
      final user = await authService.verifyOtp(
        phoneNumber: '+919876500000',
        otpToken: '123456',
      );

      expect(user.phoneNumber, '+919876500000');
      expect(user.isKycVerified, isTrue);
      expect(authService.isAuthenticated, isTrue);
    });

    test('verifyOtp with new phone creates new customer profile', () async {
      final user = await authService.verifyOtp(
        phoneNumber: '+918888877777',
        otpToken: '123456',
      );

      expect(user.phoneNumber, '+918888877777');
      expect(user.kycStatus, KycStatus.notSubmitted);
      expect(user.isKycVerified, isFalse);
    });

    test('verifyOtp throws on invalid OTP length', () async {
      expect(
        () => authService.verifyOtp(
          phoneNumber: '+919876500000',
          otpToken: '12',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('updateProfile updates user details and Driving License KYC', () async {
      await authService.verifyOtp(
        phoneNumber: '+918888877777',
        otpToken: '123456',
      );

      final updated = await authService.updateProfile(
        fullName: 'Aarav Sharma',
        email: 'aarav@example.com',
        drivingLicenseNumber: 'KA-05-2023-0098765',
        kycStatus: KycStatus.verified,
      );

      expect(updated.fullName, 'Aarav Sharma');
      expect(updated.email, 'aarav@example.com');
      expect(updated.drivingLicenseNumber, 'KA-05-2023-0098765');
      expect(updated.isKycVerified, isTrue);
    });

    test('signOut clears user and updates stream', () async {
      await authService.verifyOtp(
        phoneNumber: '+919876500000',
        otpToken: '123456',
      );
      expect(authService.isAuthenticated, isTrue);

      await authService.signOut();
      expect(authService.currentUser, isNull);
      expect(authService.isAuthenticated, isFalse);
    });
  });
}
