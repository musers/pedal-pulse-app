import 'package:flutter_test/flutter_test.dart';
import 'package:rental_subscription_platform/services/email/resend_email_service.dart';
import 'package:rental_subscription_platform/services/notification/fcm_notification_service.dart';
import 'package:rental_subscription_platform/services/sms/msg91_sms_service.dart';

void main() {
  group('Notification Services Unit Tests', () {
    test('Msg91SmsService sends OTP and booking notification in fallback mode', () async {
      final smsService = Msg91SmsService();
      expect(smsService.isConfigured, isFalse);

      final otpResult = await smsService.sendOtp(phoneNumber: '+919876500000', otp: '123456');
      expect(otpResult, isTrue);

      final notifResult = await smsService.sendBookingNotification(
        phoneNumber: '+919876500000',
        message: 'Your VeloRide booking VR-BLR-8921 is confirmed.',
      );
      expect(notifResult, isTrue);
    });

    test('ResendEmailService formats and dispatches tax receipt & agreement', () async {
      final emailService = ResendEmailService();
      expect(emailService.isConfigured, isFalse);

      final receiptResult = await emailService.sendBookingReceipt(
        toEmail: 'customer@veloride.in',
        customerName: 'Bala Gangadhar',
        bookingNumber: 'VR-BLR-8921',
        amountPaid: 1324.68,
      );
      expect(receiptResult, isTrue);

      final agreementResult = await emailService.sendRentalAgreement(
        toEmail: 'customer@veloride.in',
        customerName: 'Bala Gangadhar',
        bookingNumber: 'VR-BLR-8921',
        agreementPdfUrl: 'https://veloride.in/docs/agreement_8921.pdf',
      );
      expect(agreementResult, isTrue);
    });

    test('FcmNotificationService manages tokens and topic subscriptions', () async {
      final fcm = FcmNotificationService();
      await fcm.initialize();

      final token = await fcm.getDeviceToken();
      expect(token, isNotNull);
      expect(token!.isNotEmpty, isTrue);

      await expectLater(fcm.subscribeToTopic('hyderabad_fleet_alerts'), completes);
      await expectLater(fcm.unsubscribeFromTopic('hyderabad_fleet_alerts'), completes);
    });
  });
}
