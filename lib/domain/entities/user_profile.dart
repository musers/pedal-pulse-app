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

  UserProfile copyWith({
    String? id,
    String? phoneNumber,
    String? fullName,
    String? email,
    UserRole? role,
    KycStatus? kycStatus,
    String? drivingLicenseNumber,
    String? drivingLicenseDocUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      kycStatus: kycStatus ?? this.kycStatus,
      drivingLicenseNumber: drivingLicenseNumber ?? this.drivingLicenseNumber,
      drivingLicenseDocUrl: drivingLicenseDocUrl ?? this.drivingLicenseDocUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
