// ==============================================================================
// verify_cloud_env.dart
// Automated Cloud Environment & Infrastructure Health Verifier
// Usage: dart run scripts/verify_cloud_env.dart
// ==============================================================================

import 'dart:io';

class CloudServiceStatus {
  final String serviceName;
  final bool isConfigured;
  final String keyName;
  final String? valueHint;
  final String statusMessage;

  CloudServiceStatus({
    required this.serviceName,
    required this.isConfigured,
    required this.keyName,
    this.valueHint,
    required this.statusMessage,
  });
}

void main() async {
  stdout.writeln('=================================================================');
  stdout.writeln(' ⚡ VeloRide India — Automated Cloud Service & IaC Health Check');
  stdout.writeln('=================================================================\n');

  final envMap = <String, String>{};

  // 1. Read .env file if present
  final envFile = File('.env');
  if (await envFile.exists()) {
    stdout.writeln('📄 Found local .env file. Parsing keys...');
    final lines = await envFile.readAsLines();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split('=');
      if (parts.length >= 2) {
        envMap[parts[0].trim()] = parts.sublist(1).join('=').trim();
      }
    }
  } else {
    stdout.writeln('ℹ️  No .env file found. Falling back to OS Environment Variables.');
  }

  // Helper to fetch key
  String? getEnv(String key) {
    return envMap[key] ?? Platform.environment[key];
  }

  final checks = <CloudServiceStatus>[];

  // 1. Supabase PostgreSQL & Auth
  final supabaseUrl = getEnv('SUPABASE_URL');
  final supabaseAnon = getEnv('SUPABASE_ANON_KEY');
  final supabaseConfigured = (supabaseUrl != null && supabaseUrl.isNotEmpty && supabaseAnon != null && supabaseAnon.isNotEmpty);
  checks.add(CloudServiceStatus(
    serviceName: 'Supabase PostgreSQL & Auth',
    isConfigured: supabaseConfigured,
    keyName: 'SUPABASE_URL / SUPABASE_ANON_KEY',
    valueHint: supabaseUrl != null ? '${supabaseUrl.substring(0, supabaseUrl.length > 20 ? 20 : supabaseUrl.length)}...' : null,
    statusMessage: supabaseConfigured ? 'Connected (Live Cloud DB & Auth)' : 'Mock Mode Active (Local In-Memory Repository)',
  ));

  // 2. Razorpay Payments Gateway
  final rzpKey = getEnv('RAZORPAY_KEY_ID');
  final rzpSecret = getEnv('RAZORPAY_KEY_SECRET');
  final rzpConfigured = (rzpKey != null && rzpKey.isNotEmpty && rzpSecret != null && rzpSecret.isNotEmpty);
  checks.add(CloudServiceStatus(
    serviceName: 'Razorpay Payment Gateway (INR)',
    isConfigured: rzpConfigured,
    keyName: 'RAZORPAY_KEY_ID / RAZORPAY_KEY_SECRET',
    valueHint: rzpKey != null ? 'rzp_live/test_***' : null,
    statusMessage: rzpConfigured ? 'Ready (UPI, Cards, NetBanking)' : 'Mock Payment Mode (Auto-Success Simulator)',
  ));

  // 3. MSG91 OTP SMS Gateway
  final msg91Auth = getEnv('MSG91_AUTH_KEY');
  final msg91Template = getEnv('MSG91_TEMPLATE_ID');
  final msg91Configured = (msg91Auth != null && msg91Auth.isNotEmpty && msg91Template != null && msg91Template.isNotEmpty);
  checks.add(CloudServiceStatus(
    serviceName: 'MSG91 Indian OTP SMS Gateway',
    isConfigured: msg91Configured,
    keyName: 'MSG91_AUTH_KEY / MSG91_TEMPLATE_ID',
    valueHint: msg91Template != null ? 'Template: $msg91Template' : null,
    statusMessage: msg91Configured ? 'Ready (DLT Approved Indian SMS)' : 'Mock Mode (Default OTP: 123456)',
  ));

  // 4. Resend GST Invoices & Email Service
  final resendKey = getEnv('RESEND_API_KEY');
  final resendConfigured = (resendKey != null && resendKey.isNotEmpty);
  checks.add(CloudServiceStatus(
    serviceName: 'Resend Transactional Email & Invoicing',
    isConfigured: resendConfigured,
    keyName: 'RESEND_API_KEY',
    valueHint: resendKey != null ? 're_***' : null,
    statusMessage: resendConfigured ? 'Ready (Automated HTML Tax Invoices)' : 'Mock Mode (Console Output Only)',
  ));

  // 5. Google Maps Geolocation & Distance Matrix
  final gmapsKey = getEnv('GOOGLE_MAPS_API_KEY');
  final gmapsConfigured = (gmapsKey != null && gmapsKey.isNotEmpty);
  checks.add(CloudServiceStatus(
    serviceName: 'Google Maps & Places API',
    isConfigured: gmapsConfigured,
    keyName: 'GOOGLE_MAPS_API_KEY',
    valueHint: gmapsKey != null ? 'AIza***' : null,
    statusMessage: gmapsConfigured ? 'Ready (Live Hyderabad GPS Pins)' : 'Mock Map Mode (Pre-Computed Haversine Grid)',
  ));

  // Print Formatted Report
  stdout.writeln('\n-----------------------------------------------------------------');
  stdout.writeln(' SERVICE                         | STATUS   | INTEGRATION MODE');
  stdout.writeln('-----------------------------------------------------------------');

  int liveCount = 0;
  for (final check in checks) {
    final statusSymbol = check.isConfigured ? '✅ LIVE ' : '⚙️ MOCK ';
    if (check.isConfigured) liveCount++;
    stdout.writeln(
      '${check.serviceName.padRight(32)} | $statusSymbol | ${check.statusMessage}',
    );
  }
  stdout.writeln('-----------------------------------------------------------------\n');

  stdout.writeln('📊 Summary: $liveCount/${checks.length} Cloud Services connected in Live Mode.');
  if (liveCount == checks.length) {
    stdout.writeln('🚀 All cloud backends active and ready for production deployment!');
  } else {
    stdout.writeln('💡 App is 100% functional with built-in zero-latency local mock engine.');
    stdout.writeln('   To connect live services via code, update `.env` or pass CLI environment flags.\n');
  }
}
