import 'package:dio/dio.dart';
import 'email_service.dart';

class ResendEmailService implements EmailService {
  final String? apiKey;
  final String fromEmail;
  final Dio _dio;

  ResendEmailService({
    this.apiKey,
    this.fromEmail = 'onboarding@resend.dev',
    Dio? dio,
  }) : _dio = dio ?? Dio();

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  @override
  Future<bool> sendBookingReceipt({
    required String toEmail,
    required String customerName,
    required String bookingNumber,
    required double amountPaid,
  }) async {
    if (!isConfigured) {
      // Mock / fallback
      return true;
    }

    try {
      final html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e2e8f0; border-radius: 10px;">
          <h2 style="color: #0F766E;">⚡ VeloRide India - Rental Tax Invoice</h2>
          <p>Dear <strong>$customerName</strong>,</p>
          <p>Thank you for choosing VeloRide. Your reservation <strong>#$bookingNumber</strong> is confirmed.</p>
          <hr style="border: none; border-top: 1px solid #e2e8f0;" />
          <p style="font-size: 16px;"><strong>Amount Paid:</strong> ₹${amountPaid.toStringAsFixed(2)} (Inclusive of 18% GST)</p>
          <p>Security deposit will be credited back automatically to your VeloCash wallet upon successful hub return.</p>
          <br/>
          <p style="color: #64748b; font-size: 12px;">VeloRide Smart EV Mobility Pvt Ltd • Hyderabad (Miyapur & Kondapur Hubs)</p>
        </div>
      ''';

      final response = await _dio.post(
        'https://api.resend.com/emails',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'from': fromEmail,
          'to': [toEmail],
          'subject': 'VeloRide Booking Confirmed & GST Receipt #$bookingNumber',
          'html': html,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> sendRentalAgreement({
    required String toEmail,
    required String customerName,
    required String bookingNumber,
    required String agreementPdfUrl,
  }) async {
    if (!isConfigured) {
      return true;
    }

    try {
      final html = '''
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px;">
          <h2 style="color: #0F766E;">VeloRide Rental Agreement</h2>
          <p>Dear <strong>$customerName</strong>,</p>
          <p>Your digital two-wheeler rental contract for booking <strong>#$bookingNumber</strong> is ready.</p>
          <p><a href="$agreementPdfUrl" style="background-color: #0F766E; color: white; padding: 10px 16px; text-decoration: none; border-radius: 6px;">Download Agreement PDF</a></p>
        </div>
      ''';

      final response = await _dio.post(
        'https://api.resend.com/emails',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'from': fromEmail,
          'to': [toEmail],
          'subject': 'Digital Rental Agreement - VeloRide #$bookingNumber',
          'html': html,
        },
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}
