abstract class SmsService {
  Future<bool> sendOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<bool> sendBookingNotification({
    required String phoneNumber,
    required String message,
  });
}
