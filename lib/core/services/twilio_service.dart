import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_config_service.dart';

class TwilioService {
  final String otpSendUrl = AppConfigService.read('OTP_SEND_URL');
  final String otpVerifyUrl = AppConfigService.read('OTP_VERIFY_URL');
  final String otpDebugCode = AppConfigService.read('OTP_DEBUG_CODE');

  bool get _hasBackend => otpSendUrl.isNotEmpty && otpVerifyUrl.isNotEmpty;
  bool get _hasDebugOtp => !kReleaseMode && otpDebugCode.isNotEmpty;

  bool get supportsWebOtp => _hasBackend || _hasDebugOtp;

  /// Sends a verification code using the configured backend, or a local debug
  /// code in non-release builds.
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    if (_hasDebugOtp) {
      return {
        'success': true,
        'message':
            'Debug OTP is enabled for this build. Use the configured local test code to continue.',
        'status': 'pending',
      };
    }

    if (!_hasBackend) {
      return {
        'success': false,
        'message':
            'Phone verification is not configured for this build. Add OTP_SEND_URL and OTP_VERIFY_URL for real OTP, or OTP_DEBUG_CODE for local testing.',
      };
    }

    try {
      final response = await http.post(
        Uri.parse(otpSendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'phoneNumber': _formatPhoneNumber(phoneNumber),
        }),
      );

      return _normalizeBackendResponse(
        response,
        successMessage: 'OTP sent successfully.',
        failureMessage: 'Failed to send OTP. Try again.',
        successStatuses: const <String>{'pending', 'approved'},
      );
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
    if (_hasDebugOtp) {
      final isVerified = otpCode == otpDebugCode;
      return {
        'success': isVerified,
        'message': isVerified
            ? 'Debug OTP verified successfully.'
            : 'Invalid debug OTP. Please try again.',
        'status': isVerified ? 'approved' : 'pending',
      };
    }

    if (!_hasBackend) {
      return {
        'success': false,
        'message':
            'Phone verification is not configured for this build. Add OTP_SEND_URL and OTP_VERIFY_URL for real OTP, or OTP_DEBUG_CODE for local testing.',
      };
    }

    try {
      final response = await http.post(
        Uri.parse(otpVerifyUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'phoneNumber': _formatPhoneNumber(phoneNumber),
          'code': otpCode,
        }),
      );

      return _normalizeBackendResponse(
        response,
        successMessage: 'OTP verified successfully.',
        failureMessage: 'Invalid OTP. Please try again.',
        successStatuses: const <String>{'approved'},
      );
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

  Map<String, dynamic> _normalizeBackendResponse(
    http.Response response, {
    required String successMessage,
    required String failureMessage,
    Set<String>? successStatuses,
  }) {
    final payload = _decodePayload(response.body);
    final status = payload['status'];
    final explicitSuccess = payload['success'];
    final isHttpSuccess =
        response.statusCode >= 200 && response.statusCode < 300;
    final isAllowedStatus =
      status is String && successStatuses != null
        ? successStatuses.contains(status)
        : true;
    final isSuccess = explicitSuccess is bool
        ? explicitSuccess
      : isHttpSuccess && (status == null || isAllowedStatus);

    return <String, dynamic>{
      'success': isSuccess,
      'message': (payload['message'] as String?)?.trim().isNotEmpty == true
          ? payload['message']
          : (isSuccess ? successMessage : failureMessage),
      if (status != null) 'status': status,
      if (payload['sid'] != null) 'sid': payload['sid'],
      if (!isSuccess && response.body.trim().isNotEmpty) 'error': response.body,
    };
  }

  Map<String, dynamic> _decodePayload(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{'message': decoded.toString()};
    } catch (_) {
      return <String, dynamic>{'message': responseBody};
    }
  }
}
