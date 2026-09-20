import 'package:dio/dio.dart';
import 'sms_service.dart';

class Msg91SmsService implements SmsService {
  final String? authKey;
  final String? templateId;
  final String senderId;
  final Dio _dio;

  Msg91SmsService({
    this.authKey,
    this.templateId,
    this.senderId = 'VELORD',
    Dio? dio,
  }) : _dio = dio ?? Dio();

  bool get isConfigured => authKey != null && authKey!.isNotEmpty;

  @override
  Future<bool> sendOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    if (!isConfigured) {
      // Mock mode fallback
      return true;
    }

    try {
      final cleanPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
      final response = await _dio.get(
        'https://control.msg91.com/api/v5/otp',
        queryParameters: {
          'authkey': authKey,
          'template_id': templateId,
          'mobile': cleanPhone,
          if (otp.isNotEmpty && otp != 'auto') 'otp': otp,
        },
      );

      return response.statusCode == 200 && response.data['type'] != 'error';
    } catch (_) {
      return false;
    }
  }

  /// Verifies the OTP entered by the user against MSG91 OTP Engine
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otpToken,
  }) async {
    if (!isConfigured) {
      return otpToken == '123456';
    }

    try {
      final cleanPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
      final response = await _dio.get(
        'https://control.msg91.com/api/v5/otp/verify',
        queryParameters: {
          'authkey': authKey,
          'mobile': cleanPhone,
          'otp': otpToken,
        },
      );

      return response.statusCode == 200 && response.data['type'] == 'success';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> sendBookingNotification({
    required String phoneNumber,
    required String message,
  }) async {
    if (!isConfigured) {
      return true;
    }

    try {
      final cleanPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
      final response = await _dio.post(
        'https://control.msg91.com/api/v5/flow/',
        options: Options(
          headers: {
            'authkey': authKey!,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'sender': senderId,
          'mobiles': cleanPhone,
          'message': message,
        },
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
