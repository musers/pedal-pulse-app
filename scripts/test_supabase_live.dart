import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final supabaseUrl = 'https://bpgabdordakgiwkmgdzo.supabase.co';
  final anonKey = 'sb_publishable_4J-j_0SCDy6vJDJX2GV2lA_XwPsV1Rl';

  stdout.writeln('Testing live connection to Supabase REST API...');
  
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/stations?select=*'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    );

    stdout.writeln('HTTP Status: ${response.statusCode}');
    stdout.writeln('Response: ${response.body}');

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      stdout.writeln('✅ Success! Found ${list.length} stations in live database.');
    } else if (response.statusCode == 404 || response.body.contains('relation "public.stations" does not exist')) {
      stdout.writeln('⚠️ Tables not created yet. Please run the SQL migrations in Supabase SQL Editor.');
    }
  } catch (e) {
    stdout.writeln('❌ Connection error: $e');
  }
}
