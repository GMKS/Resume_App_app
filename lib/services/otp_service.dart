import 'dart:math';
import 'package:flutter/foundation.dart'; // For kDebugMode

class OtpService {
  static final Map<String, String> _otps = {};
  static final Map<String, DateTime> _otpTimestamps = {};
  static const int _otpValidityMinutes = 5;

  // Generate and send OTP for email or mobile number
  static String sendOtp(String user) {
    final otp = (100000 + Random().nextInt(900000)).toString();
    _otps[user] = otp;
    _otpTimestamps[user] = DateTime.now();

    // In a real app, you would send the OTP via SMS or email here
    // For development/testing: Check console logs only (not visible to end users)
    if (kDebugMode) {
      if (user.contains('@')) {
        print('Email OTP for $user: $otp');
      } else {
        print('SMS OTP for $user: $otp');
      }
    }

    return otp;
  }

  // Send OTP specifically for mobile number with country code
  static String sendMobileOtp(String countryCode, String mobileNumber) {
    final fullNumber = '$countryCode$mobileNumber';
    final otp = (100000 + Random().nextInt(900000)).toString();
    _otps[fullNumber] = otp;
    _otpTimestamps[fullNumber] = DateTime.now();

    // In a real app, integrate with SMS service like Twilio, Firebase Auth, etc.
    // For development/testing: Check console logs only (not visible to end users)
    if (kDebugMode) {
      print('SMS OTP sent to $fullNumber: $otp');
    }

    return otp;
  }

  // Verify OTP with expiry check
  static bool verifyOtp(String user, String otp) {
    final storedOtp = _otps[user];
    final timestamp = _otpTimestamps[user];

    if (storedOtp == null || timestamp == null) return false;

    // Check if OTP has expired
    final now = DateTime.now();
    final difference = now.difference(timestamp).inMinutes;
    if (difference > _otpValidityMinutes) {
      clearOtp(user);
      return false;
    }

    return storedOtp == otp;
  }

  // Verify mobile OTP
  static bool verifyMobileOtp(
    String countryCode,
    String mobileNumber,
    String otp,
  ) {
    final fullNumber = '$countryCode$mobileNumber';
    return verifyOtp(fullNumber, otp);
  }

  // Clear OTP for user
  static void clearOtp(String user) {
    _otps.remove(user);
    _otpTimestamps.remove(user);
  }

  // Clear mobile OTP
  static void clearMobileOtp(String countryCode, String mobileNumber) {
    final fullNumber = '$countryCode$mobileNumber';
    clearOtp(fullNumber);
  }

  // Check if OTP exists and is valid for user
  static bool hasValidOtp(String user) {
    final timestamp = _otpTimestamps[user];
    if (timestamp == null) return false;

    final now = DateTime.now();
    final difference = now.difference(timestamp).inMinutes;
    return difference <= _otpValidityMinutes;
  }

  // Format mobile number for storage/comparison
  static String formatMobileNumber(String countryCode, String mobileNumber) {
    return '$countryCode$mobileNumber';
  }
}
