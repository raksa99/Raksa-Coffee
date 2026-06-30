class EnvConfig {
  // ==========================================
  // BAKONG CONFIGURATIONS
  // ==========================================
  static const String bakongAccountId = 'raksa_em@bkrt';
  static const String bakongMerchantName = 'Raksa Coffee';
  static const String bakongMerchantCity = 'Phnom Penh';
  static const String bakongApiBaseUrl = 'https://api-bakong.nbc.gov.kh';
  static const String bakongToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImlkIjoiNTA4NTQ2ZWEzMWQ2NDFhOSJ9LCJpYXQiOjE3ODI3NDczMzYsImV4cCI6MTc5MDUyMzMzNn0.Atd78MIIhuxaTKvbspPnRSS2c3L7-XhL8uf8S1IM6Ag'; // Enter your Bakong Bearer Access Token here
  static const String corsProxyUrl = ''; // Set empty to make direct API calls when running Chrome with --disable-web-security

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
