import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/email/email_service.dart';
import '../../../services/email/resend_email_service.dart';
import '../../../services/notification/fcm_notification_service.dart';
import '../../../services/notification/notification_service.dart';
import '../../../services/sms/msg91_sms_service.dart';
import '../../../services/sms/sms_service.dart';

final smsServiceProvider = Provider<SmsService>((ref) {
  const msg91Key = String.fromEnvironment('MSG91_AUTH_KEY', defaultValue: '');
  return Msg91SmsService(authKey: msg91Key.isNotEmpty ? msg91Key : null);
});

final emailServiceProvider = Provider<EmailService>((ref) {
  const resendKey = String.fromEnvironment('RESEND_API_KEY', defaultValue: '');
  return ResendEmailService(apiKey: resendKey.isNotEmpty ? resendKey : null);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = FcmNotificationService();
  service.initialize();
  return service;
});
