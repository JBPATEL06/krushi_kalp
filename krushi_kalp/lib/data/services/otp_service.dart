import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Custom exceptions for clear UI error handling
class OtpRateLimitException implements Exception {
  final String message;
  OtpRateLimitException(
      [this.message = 'Too many requests. Please wait before resending.']);
  @override
  String toString() => message;
}

class OtpExpiredException implements Exception {
  final String message;
  OtpExpiredException(
      [this.message = 'OTP has expired. Please request a new one.']);
  @override
  String toString() => message;
}

class OtpWrongException implements Exception {
  final String message;
  OtpWrongException([this.message = 'Invalid OTP. Please try again.']);
  @override
  String toString() => message;
}

/// MSG91 OTP Service — routes all calls through the Supabase Edge Function
/// so the MSG91 API key stays safely on the server and IP whitelisting works.
/// Completely isolated from push_notification and send-fcm edge functions.
class OtpService {
  static String get _edgeFnUrl {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    return '$supabaseUrl/functions/v1/otp';
  }

  static String get _anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> _call(Map<String, dynamic> body) async {
    final uri = Uri.parse(_edgeFnUrl);
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_anonKey',
            'apikey': _anonKey,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    final resp = jsonDecode(response.body) as Map<String, dynamic>;
    

    if (resp['success'] == true) return; // All good

    final error = (resp['error'] as String? ?? 'Unknown error').toLowerCase();
    if (error.contains('rate') || error.contains('wait'))
      throw OtpRateLimitException(resp['error']);
    if (error.contains('expir')) throw OtpExpiredException(resp['error']);
    if (error.contains('invalid') || error.contains('wrong'))
      throw OtpWrongException(resp['error']);
    throw Exception(resp['error'] ?? 'OTP request failed.');
  }

  /// Sends a new OTP to [phone] (10-digit Indian number).
  static Future<void> sendOtp(String phone) async {
    _validatePhone(phone);
    await _call({'action': 'send', 'phone': _clean(phone)});
  }

  /// Resends OTP to [phone] via MSG91 retry endpoint.
  static Future<void> resendOtp(String phone) async {
    _validatePhone(phone);
    await _call({'action': 'resend', 'phone': _clean(phone)});
  }

  /// Verifies [otp] for [phone]. Returns true if valid, throws otherwise.
  static Future<bool> verifyOtp(String phone, String otp) async {
    _validatePhone(phone);
    if (otp.trim().length != 6)
      throw OtpWrongException('Please enter a 6-digit OTP.');
    await _call(
        {'action': 'verify', 'phone': _clean(phone), 'otp': otp.trim()});
    return true;
  }

  static String _clean(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

  static void _validatePhone(String phone) {
    if (_clean(phone).length != 10) {
      throw ArgumentError('Please enter a valid 10-digit phone number.');
    }
  }
}
