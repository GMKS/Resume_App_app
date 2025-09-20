import 'dart:math';

class OtpService {
  static final Map<String, String> _otps = {};
  static String sendOtp(String user) {
    final otp = (100000 + Random().nextInt(900000)).toString();
    _otps[user] = otp;
    return otp;
  }

  static bool verifyOtp(String user, String otp) => _otps[user] == otp;
  static void clearOtp(String user) => _otps.remove(user);
}
