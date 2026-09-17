abstract class EmailService {
  Future<bool> sendBookingReceipt({
    required String toEmail,
    required String customerName,
    required String bookingNumber,
    required double amountPaid,
  });

  Future<bool> sendRentalAgreement({
    required String toEmail,
    required String customerName,
    required String bookingNumber,
    required String agreementPdfUrl,
  });
}
