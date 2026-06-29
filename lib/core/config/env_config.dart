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

  // ==========================================
  // SUPABASE CONFIGURATIONS
  // ==========================================
  static const String supabaseUrl = 'https://kuksgolxnnnvjkiwvuzr.supabase.co'; // Enter your Supabase project URL here
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt1a3Nnb2x4bm5udmpraXd2dXpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIwMTEyOTYsImV4cCI6MjA5NzU4NzI5Nn0.F0I17NzcChiUfJbIs_YiBmkLvKAYUI67C49_fZpvZvg'; // Enter your Supabase Anon Key here
}
