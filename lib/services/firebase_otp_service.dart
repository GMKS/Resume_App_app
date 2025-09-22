import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseOtpService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static String? _verificationId;
  static int? _resendToken;

  // Send OTP to mobile number using Firebase Auth
  static Future<bool> sendMobileOtp({
    required String countryCode,
    required String mobileNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
    Function(PhoneAuthCredential)? onAutoVerify,
  }) async {
    try {
      final String phoneNumber = '$countryCode$mobileNumber';

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          if (kDebugMode) {
            print('Auto-verification completed');
          }
          onAutoVerify?.call(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Verification failed';

          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number format';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later';
              break;
            default:
              errorMessage = e.message ?? 'Verification failed';
          }

          if (kDebugMode) {
            print('Verification failed: ${e.code} - ${e.message}');
          }
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;

          if (kDebugMode) {
            print('SMS code sent to $phoneNumber');
          }
          onCodeSent('SMS sent successfully');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (kDebugMode) {
            print('Auto-retrieval timeout');
          }
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending OTP: $e');
      }
      onError('Failed to send OTP. Please try again.');
      return false;
    }
  }

  // Verify OTP code
  static Future<PhoneAuthCredential?> verifyOtp(String otpCode) async {
    try {
      if (_verificationId == null) {
        throw Exception('No verification ID available');
      }

      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      return credential;
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying OTP: $e');
      }
      return null;
    }
  }

  // Sign in with phone credential
  static Future<UserCredential?> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Sign-in failed: ${e.code} - ${e.message}');
      }
      return null;
    }
  }

  // Check if user is signed in
  static User? get currentUser => _firebaseAuth.currentUser;

  // Sign out
  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _verificationId = null;
    _resendToken = null;
  }

  // Resend OTP
  static Future<bool> resendOtp({
    required String countryCode,
    required String mobileNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    return await sendMobileOtp(
      countryCode: countryCode,
      mobileNumber: mobileNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }
}
