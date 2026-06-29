class EnvConfig {
  // ==========================================
  // BAKONG CONFIGURATIONS
  // ==========================================
  static const String bakongAccountId = 'raksa_em@bkrt';
  static const String bakongMerchantName = 'Raksa Coffee';
  static const String bakongMerchantCity = 'Phnom Penh';

  // ==========================================
  // ABA PAYWAY CONFIGURATIONS (SANDBOX)
  // ==========================================
  static const String abaMerchantId = ''; // e.g. 'ec38283'
  static const String abaApiKey = '';     // API Key (Public)
  static const String abaApiSecret = '';  // API Secret (Private)

  // ==========================================
  // PAYMENT SYSTEM SETTINGS
  // ==========================================
  // Active QR provider: 'bakong' or 'aba'
  static const String defaultQrProvider = 'bakong';
}
