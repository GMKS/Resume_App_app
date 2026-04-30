import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TwilioService {
  final String accountSid = _readEnv('TWILIO_ACCOUNT_SID');
  final String authToken = _readEnv('TWILIO_AUTH_TOKEN');
  final String verifyServiceSid = _readEnv('TWILIO_VERIFY_SERVICE_SID');

  // Correct Twilio Verify v2 base URL
  static const String _verifyBaseUrl = 'https://verify.twilio.com/v2';

  bool get _hasCredentials =>
      accountSid.isNotEmpty &&
      authToken.isNotEmpty &&
      verifyServiceSid.isNotEmpty;

  static String _readEnv(String key) {
    var value = dotenv.env[key]?.trim() ?? '';
    if (value.endsWith(';')) {
      value = value.substring(0, value.length - 1).trimRight();
    }
    if (value.length >= 2 &&
        ((value.startsWith("'") && value.endsWith("'")) ||
            (value.startsWith('"') && value.endsWith('"')))) {
      value = value.substring(1, value.length - 1);
    }
    return value;
  }

  /// Send OTP via SMS using Twilio Verify Service
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    // Web browsers block direct Twilio API calls due to CORS
    if (kIsWeb) {
      return {
        'success': false,
        'message':
            'SMS OTP is not supported on web. Please use the mobile app.',
      };
    }

    if (!_hasCredentials) {
      return {
        'success': false,
        'message': 'Twilio credentials are missing. Check your .env file.',
      };
    }

    try {
      final url = Uri.parse(
        '$_verifyBaseUrl/Services/$verifyServiceSid/Verifications',
      );

      final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': _formatPhoneNumber(phoneNumber),
          'Channel': 'sms',
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'OTP sent successfully',
          'sid': data['sid'],
        };
      } else {
        final error = jsonDecode(response.body);
        final errorCode = error['code'];
        return {
          'success': false,
          'message': _getTwilioErrorMessage(errorCode),
          'error': response.body,
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Verify OTP entered by user
  Future<Map<String, dynamic>> verifyOTP(
    String phoneNumber,
    String otpCode,
  ) async {
    if (kIsWeb) {
      return {
        'success': false,
        'message':
            'SMS OTP is not supported on web. Please use the mobile app.',
      };
    }

    if (!_hasCredentials) {
      return {
        'success': false,
        'message': 'Twilio credentials are missing. Check your .env file.',
      };
    }

    try {
      final url = Uri.parse(
        '$_verifyBaseUrl/Services/$verifyServiceSid/VerificationCheck',
      );

      final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'To': _formatPhoneNumber(phoneNumber),
          'Code': otpCode,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isVerified = data['status'] == 'approved';

        if (isVerified) {
          return {
            'success': true,
            'message': 'OTP verified successfully',
            'status': data['status'],
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid OTP. Please try again.',
            'status': data['status'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to verify OTP. Try again.',
          'error': response.body,
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Format phone number to E.164 format (+CountryCodeNumber)
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (!cleaned.startsWith('+')) {
      if (cleaned.length == 10) {
        cleaned = '+1$cleaned'; // Default to US
      } else {
        cleaned = '+$cleaned';
      }
    }

    return cleaned;
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.length >= 10 && cleaned.length <= 15;
  }

  /// Resend OTP (request new code)
  Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    return sendOTP(phoneNumber);
  }

  /// Convert Twilio error codes to user-friendly messages
  String _getTwilioErrorMessage(dynamic errorCode) {
    switch (errorCode) {
      case 60033:
        return 'This number is not verified on our Twilio trial account.\n\nTo fix: Go to twilio.com → Phone Numbers → Verified Caller IDs and add your number.';
      case 60200:
        return 'Invalid phone number format. Please include country code (e.g. +1 234 567 8900).';
      case 60203:
        return 'Too many OTP attempts for this number. Please wait 10 minutes and try again.';
      case 60212:
        return 'Too many OTP requests. Please wait a moment before requesting a new code.';
      case 20003:
        return 'Authentication error. Please check Twilio credentials.';
      case 20404:
        return 'Twilio Verify Service not found. Please check your Service SID.';
      default:
        return 'Failed to send OTP (code $errorCode). Please try again.';
    }
  }
}
