# Twilio Login System

## Overview

This Twilio-based authentication system provides SMS OTP (One-Time Password) verification for secure user login with an animated UI experience.

## Features

✨ **User Experience:**
- Phone number entry with country code selector
- 6-digit SMS OTP verification
- Auto-advance between OTP fields
- Resend OTP with countdown timer
- Real-time validation feedback
- Combined animations: Loading spinners, slide effects, fade transitions
- Dark mode support
- Card-based UI design

🔐 **Security:**
- Uses Twilio Verify Service API
- Phone number validation
- E.164 format phone number formatting
- Rate limiting via Twilio

## Project Structure

```
lib/features/auth/
├── screens/
│   └── twilio_login_screen.dart       # Main login screen with orchestration
├── widgets/
│   ├── phone_entry_widget.dart        # Phone input form
│   ├── otp_verification_widget.dart   # OTP verification form
│   └── loading_animation_widget.dart   # Loading & animation effects
└── auth.dart                           # Barrel export file

lib/core/services/
└── twilio_service.dart                 # Twilio API integration
```

## Setup Instructions

### 1. Configure OTP Backend

1. Deploy server-side OTP endpoints that keep Twilio credentials off the client.
2. Expose a send endpoint and a verify endpoint.
3. Set `OTP_SEND_URL` and `OTP_VERIFY_URL` in `.env` or with `--dart-define`.
4. For local-only debug testing, optionally set `OTP_DEBUG_CODE` to a fixed code.

This repo now includes matching Supabase Edge Function scaffolding in
`supabase/functions/` for `send-otp` and `verify-otp`.

### 2. Keep Secrets Off The Client

Do not place Twilio Account SID, Auth Token, or Verify Service SID in the app.
The mobile and web clients should only know the backend endpoints:

```env
OTP_SEND_URL=https://your-backend.example.com/otp/send
OTP_VERIFY_URL=https://your-backend.example.com/otp/verify
OTP_DEBUG_CODE=
```

### 3. Add Route to Navigation

Edit your router/navigation file (e.g., `lib/core/router/app_router.dart`):

```dart
import 'package:resume_builder/features/auth/auth.dart';

// Add to your routes:
GoRoute(
  path: '/login',
  builder: (context, state) => const TwilioLoginScreen(),
),

// Make it the initial route:
initialLocation: '/login',
```

### 4. Update Firebase Auth (Optional)

If using Firebase Auth, update your auth flow:

```dart
// After successful OTP verification in twilio_login_screen.dart
// you can sign in with Firebase:

Future<void> _signInWithFirebase(String phone) async {
  try {
    // Sign in anonymously or with custom token
    await FirebaseAuth.instance.signInAnonymously();
    // or await FirebaseAuth.instance.signInWithCustomToken(token);
  } catch (e) {
    // Handle the sign-in failure in your UI.
  }
}
```

## Usage

### Basic Navigation

```dart
import 'package:resume_builder/features/auth/auth.dart';

// Navigate to login screen
Navigator.of(context).pushNamed('/login');
```

### Programmatic OTP Sending

```dart
import 'package:resume_builder/core/services/twilio_service.dart';

final twilioService = TwilioService();

// Send OTP
final result = await twilioService.sendOTP('+1234567890');
if (!result['success']) {
  // Show result['message'] to the user.
}

// Verify OTP
final verifyResult = await twilioService.verifyOTP('+1234567890', '123456');
if (!verifyResult['success']) {
  // Show verifyResult['message'] to the user.
}
```

## Animation Components

### LoadingAnimationWidget
Displays a rotating ring animation with pulsing center:

```dart
LoadingAnimationWidget(
  color: Colors.blue.shade600,
  size: 60,
)
```

### GradientLoadingWidget
Alternative gradient-based loading indicator:

```dart
GradientLoadingWidget(size: 60)
```

### ModernLoadingBar
Linear progress bar animation:

```dart
ModernLoadingBar(
  height: 3,
  color: Colors.blue.shade600,
)
```

## Phone Number Validation

The system automatically:
- Removes special characters: `()-. `
- Detects US numbers without country code (adds `+1`)
- Formats to E.164 standard: `+<CountryCode><Number>`

Examples:
```
"555-123-4567" → "+15551234567"
"(555) 123-4567" → "+15551234567"
"+1-555-123-4567" → "+15551234567"
"+44 20 7946 0958" → "+442079460958"
```

## Error Handling

The system provides user-friendly error messages:

| Error | Message |
|-------|---------|
| Invalid phone | "Invalid phone number" |
| OTP send failed | "Failed to send OTP. Try again." |
| Network error | "Network error. Please check your connection." |
| Wrong OTP | "Invalid OTP. Please try again." |

## Customization

### Change UI Colors

```dart
// In twilio_login_screen.dart
backgroundColor: isDarkMode ? Colors.black87 : Colors.grey.shade100,

// In phone_entry_widget.dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green.shade600, // Change button color
  ),
)
```

### Adjust Animation Durations

```dart
// Fade animation
const Duration(milliseconds: 800) // Change timing

// Rotate animation
.rotate(duration: const Duration(milliseconds: 1500))
```

### Customize OTP Length

```dart
// In otp_verification_widget.dart
List.generate(4, (_) => TextEditingController()) // For 4-digit OTP
```

## Testing

### Backend Test Mode

For local development, set `OTP_DEBUG_CODE=123456` in `.env` and use `123456`
to complete the flow on mobile or Chrome debug builds.

### Mock Testing

```dart
// Create a mock TwilioService for testing
class MockTwilioService extends TwilioService {
  @override
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    return {
      'success': true,
      'message': 'OTP sent successfully',
      'sid': 'test-sid-123',
    };
  }
  
  @override
  Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otpCode) async {
    return {
      'success': otpCode == '123456',
      'message': otpCode == '123456' ? 'OTP verified successfully' : 'Invalid OTP',
      'status': otpCode == '123456' ? 'approved' : 'pending',
    };
  }
}
```

## Security Considerations

⚠️ **IMPORTANT:**

1. **Never commit provider credentials** - keep Twilio secrets server-side only.

2. **Use Firebase Cloud Functions or any secure backend** for server-side OTP handling:
   ```javascript
   // functions/index.js
   exports.sendOTP = functions.https.onCall(async (data, context) => {
     // Server-side Twilio call
     return twilio.verify.v2.services(SERVICE_SID)
       .verifications.create({ to: data.phone, channel: 'sms' });
   });
   ```

3. **Implement Rate Limiting** - your provider can still enforce delivery limits
4. **HTTPS Only** - Always use secure connections
5. **Validate on Backend** - Never trust client-side OTP verification alone

## API Reference

### TwilioService

#### `sendOTP(String phoneNumber)`
Sends OTP via SMS.

**Parameters:**
- `phoneNumber` (String): Phone number in any format

**Returns:**
```dart
{
  'success': bool,
  'message': String,
  'sid': String? // Verification SID for tracking
}
```

#### `verifyOTP(String phoneNumber, String otpCode)`
Verifies user-entered OTP.

**Parameters:**
- `phoneNumber` (String): Phone number
- `otpCode` (String): 6-digit OTP code

**Returns:**
```dart
{
  'success': bool,
  'message': String,
  'status': String? // 'approved' or 'pending'
}
```

#### `resendOTP(String phoneNumber)`
Alias for `sendOTP()` to request a new OTP.

#### `isValidPhoneNumber(String phone)`
Validates phone number format.

**Returns:** `bool`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "OTP not received" | Check your backend send endpoint, provider status, and test number |
| "Invalid credentials" | Verify backend-held provider credentials and endpoint auth |
| "Phone number rejected" | Use E.164 format with country code; check carrier support |
| "Rate limit exceeded" | Wait before resending; Twilio throttles excessive requests |
| "Animation stuttering" | Reduce animation duration; check device performance |

## Future Enhancements

- [ ] WhatsApp OTP delivery option
- [ ] Voice call OTP delivery
- [ ] Biometric authentication fallback
- [ ] OAuth integration (Google/Apple)
- [ ] Multi-language support
- [ ] SMS delivery tracking/status

## Support

For issues:
1. Check Twilio Console for service status
2. Inspect returned error messages in your debugger or UI
3. Check network connectivity
4. Verify phone number format

---

**Created:** 2025
**Last Updated:** 2025
**Twilio Verify API Version:** Latest
