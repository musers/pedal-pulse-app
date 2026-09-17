enum KycStatus {
  notSubmitted,
  pendingReview,
  verified,
  rejected,
}

enum UserRole {
  customer,
  admin,
  stationStaff,
}

class UserProfile {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String? email;
  final UserRole role;
  final KycStatus kycStatus;
  final String? drivingLicenseNumber;
  final String? drivingLicenseDocUrl;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.phoneNumber,
    this.fullName = '',
    this.email,
    this.role = UserRole.customer,
    this.kycStatus = KycStatus.notSubmitted,
    this.drivingLicenseNumber,
    this.drivingLicenseDocUrl,
    required this.createdAt,
  });

  bool get isKycVerified => kycStatus == KycStatus.verified;
}
