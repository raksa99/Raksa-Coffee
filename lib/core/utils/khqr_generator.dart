class KhqrGenerator {
  /// Generates a standardized EMVCo KHQR payload string for Bakong payments.
  static String generate({
    required String accountId,
    required String merchantName,
    required String merchantCity,
    required double amount,
    required String orderNumber,
  }) {
    // Helper to format Tag-Length-Value (TLV) block
    String tlv(String tag, String value) {
      final len = value.length.toString().padLeft(2, '0');
      return '$tag$len$value';
    }

    // 1. Build Tag 29 (Merchant Account Information - Bakong)
    final subTag00 = tlv('00', 'kh.gov.nbc.bakong');
    final subTag01 = tlv('01', accountId);
    final subTag02 = tlv('02', merchantName);
    final tag29Value = '$subTag00$subTag01$subTag02';
    final tag29 = tlv('29', tag29Value);

    // 2. Build Core EMV Tags
    final tag00 = tlv('00', '01'); // Payload Format Indicator
    final tag01 = tlv('01', '12'); // Point of Initiation Method: 12 (Dynamic QR)
    final tag52 = tlv('52', '5812'); // Merchant Category Code (MCC): 5812 (Restaurants)
    final tag53 = tlv('53', '840'); // Currency Code: 840 (US Dollar)
    final tag54 = tlv('54', amount.toStringAsFixed(2)); // Transaction Amount
    final tag58 = tlv('58', 'KH'); // Country Code: KH
    final tag59 = tlv('59', merchantName); // Merchant Name
    final tag60 = tlv('60', merchantCity); // Merchant City
    
    // Tag 62: Additional Data Field Template (Order Reference Number)
    final subTag01Bill = tlv('01', orderNumber);
    final tag62 = tlv('62', subTag01Bill);

    // 3. Assemble full payload up to Tag 63 (CRC) indicating a 4-char hex length
    final incompletePayload = '$tag00$tag01$tag29$tag52$tag53$tag54$tag58$tag59$tag60$tag62' '6304';

    // 4. Calculate standard CRC16 CCITT-FALSE Checksum
    final crc = _calculateCRC16(incompletePayload);
    final crcHex = crc.toRadixString(16).padLeft(4, '0').toUpperCase();

    // 5. Return completed EMVCo payload string
    return '$incompletePayload$crcHex';
  }

  /// Calculates CRC-16/CCITT-FALSE checksum (polynomial: 0x1021, init: 0xFFFF).
  static int _calculateCRC16(String data) {
    List<int> bytes = data.codeUnits;
    int crc = 0xFFFF;
    const int polynomial = 0x1021;

    for (int byte in bytes) {
      for (int i = 0; i < 8; i++) {
        bool bit = ((byte >> (7 - i)) & 1) == 1;
        bool c15 = ((crc >> 15) & 1) == 1;
        crc <<= 1;
        if (c15 ^ bit) {
          crc ^= polynomial;
        }
      }
    }
    return crc & 0xFFFF;
  }
}
