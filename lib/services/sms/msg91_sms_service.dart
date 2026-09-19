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
      // Mock / fallback mode
      return true;
    }

    try {
      final cleanPhone = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
      final response = await _dio.post(
        'https://control.msg91.com/api/v5/otp',
        options: Options(
          headers: {
            'authkey': authKey!,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'template_id': templateId ?? '',
          'mobile': cleanPhone,
          'otp': otp,
        },
      );

      return response.statusCode == 200;
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
