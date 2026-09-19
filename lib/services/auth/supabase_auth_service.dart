import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile.dart';
import 'auth_service.dart';

class SupabaseAuthService implements AuthService {
  final SupabaseClient client;

  SupabaseAuthService(this.client);

  @override
  Stream<UserProfile?> get authStateChanges {
    return client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;
      return _fetchOrCreateProfile(user);
    });
  }

  @override
  UserProfile? get currentUser {
    final user = client.auth.currentUser;
    if (user == null) return null;
    // Fast synchronous representation; detailed fields loaded via profile
    return UserProfile(
      id: user.id,
      phoneNumber: user.phone ?? '',
      email: user.email,
      role: UserRole.customer,
      kycStatus: KycStatus.notSubmitted,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  @override
  bool get isAuthenticated => client.auth.currentUser != null;

  @override
  Future<void> sendOtp({required String phoneNumber}) async {
    await client.auth.signInWithOtp(phone: phoneNumber);
  }

  @override
  Future<UserProfile> verifyOtp({
    required String phoneNumber,
    required String otpToken,
  }) async {
    final response = await client.auth.verifyOTP(
      phone: phoneNumber,
      token: otpToken,
      type: OtpType.sms,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Authentication failed. No user returned.');
    }

    return _fetchOrCreateProfile(user);
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  @override
  Future<UserProfile> updateProfile({
    String? fullName,
    String? email,
    String? drivingLicenseNumber,
    String? drivingLicenseDocUrl,
    KycStatus? kycStatus,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (fullName != null) updates['full_name'] = fullName;
    if (email != null) updates['email'] = email;
    if (drivingLicenseNumber != null) {
      updates['driving_license_number'] = drivingLicenseNumber;
      updates['kyc_status'] = 'pending_review';
    }
    if (drivingLicenseDocUrl != null) {
      updates['driving_license_doc_url'] = drivingLicenseDocUrl;
    }
    if (kycStatus != null) {
      updates['kyc_status'] = _mapKycStatusToString(kycStatus);
    }

    final data = await client
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select()
        .single();

    return _mapJsonToProfile(data);
  }

  Future<UserProfile> _fetchOrCreateProfile(User user) async {
    try {
      final existing = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) {
        return _mapJsonToProfile(existing);
      }

      // First time login: create profile row
      final newRow = {
        'id': user.id,
        'phone': user.phone ?? '',
        'email': user.email,
        'role': 'customer',
        'kyc_status': 'not_submitted',
        'created_at': DateTime.now().toIso8601String(),
      };

      final inserted = await client
          .from('profiles')
          .insert(newRow)
          .select()
          .single();

      return _mapJsonToProfile(inserted);
    } catch (e) {
      // Fallback
      return UserProfile(
        id: user.id,
        phoneNumber: user.phone ?? '',
        email: user.email,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    }
  }

  UserProfile _mapJsonToProfile(Map<String, dynamic> json) {
    UserRole role;
    switch (json['role']) {
      case 'admin':
        role = UserRole.admin;
        break;
      case 'station_staff':
        role = UserRole.stationStaff;
        break;
      default:
        role = UserRole.customer;
    }

    KycStatus kycStatus;
    switch (json['kyc_status']) {
      case 'verified':
        kycStatus = KycStatus.verified;
        break;
      case 'pending_review':
        kycStatus = KycStatus.pendingReview;
        break;
      case 'rejected':
        kycStatus = KycStatus.rejected;
        break;
      default:
        kycStatus = KycStatus.notSubmitted;
    }

    return UserProfile(
      id: json['id'] as String,
      phoneNumber: json['phone'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      role: role,
      kycStatus: kycStatus,
      drivingLicenseNumber: json['driving_license_number'] as String?,
      drivingLicenseDocUrl: json['driving_license_doc_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String _mapKycStatusToString(KycStatus status) {
    switch (status) {
      case KycStatus.verified:
        return 'verified';
      case KycStatus.pendingReview:
        return 'pending_review';
      case KycStatus.rejected:
        return 'rejected';
      case KycStatus.notSubmitted:
        return 'not_submitted';
    }
  }
}
