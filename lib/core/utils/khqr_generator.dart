import 'package:khqr_generator/khqr_generator.dart';

class KhqrGenerator {
  /// Generates a standardized EMVCo KHQR payload string for Bakong payments.
  static String generate({
    required String accountId,
    required String merchantName,
    required String merchantCity,
    required double amount,
    required String orderNumber,
  }) {
    // Determine the currency based on the account ID suffix
    final isKhr = accountId.toLowerCase().endsWith('@khr');
    
    // If it's KHR, we must format it as KHR and convert the USD order total (1 USD = 4,000 KHR)
    final khqrAmount = isKhr ? (amount * 4000) : amount;
    final khqrCurrency = isKhr ? KHQRCurrency.khr : KHQRCurrency.usd;

    // Use the official community-standardized generator
    final individualInfo = IndividualInfo(
      bakongAccountID: accountId,
      merchantName: merchantName,
      merchantCity: merchantCity,
      amount: khqrAmount,
      currency: khqrCurrency.code,
    );

    final response = KHQRGenerator.generateIndividual(individualInfo);

    if (response.data == null) {
      throw Exception('KHQR Generation failed: Invalid account format or parameters');
    }

    return response.data!.qr;
  }
}
