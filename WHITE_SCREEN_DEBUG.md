# White Screen Debugging Guide

_Comprehensive guide to diagnose and fix white screen issues_

## 🔍 ISSUE IDENTIFIED

**Problem**: White screen appears when APK is installed on physical device
**Status**: Under investigation with enhanced debugging

## 🛠️ DEBUGGING STEPS IMPLEMENTED

### 1. Enhanced Error Handling

- Added comprehensive error catching in `main()`
- Created `ErrorApp` widget to show errors instead of white screen
- Added error handling in service initialization
- Enhanced debug logging throughout the app

### 2. Configuration Updates

- Disabled development/testing flags in production
- Updated app config for release build
- Added fallback screens for failed initialization

### 3. Created Debug Version

- `lib/main_debug.dart` - Minimal app to test basic functionality
- Bypasses Firebase and service initialization
- Confirms Flutter framework is working

## 🔧 IMMEDIATE TROUBLESHOOTING

### Step 1: Test Debug Version

```bash
# Build and test with debug main file
flutter build apk --release -t lib/main_debug.dart --target-platform android-arm64
```

### Step 2: Check Device Logs

```bash
# Connect device via ADB and check logs
adb logcat | grep -E "(flutter|resume|ERROR|FATAL)"
```

### Step 3: Test Network Connectivity

- Ensure device has internet connection
- Firebase requires internet for initialization
- Check if firewall is blocking connections

## 🚨 COMMON CAUSES & SOLUTIONS

### 1. Firebase Initialization Issues

**Symptoms**: White screen, no error messages
**Solutions**:

- ✅ Added error handling for Firebase init
- ✅ Created fallback error screens
- ✅ Enhanced logging for debugging

### 2. Missing Dependencies

**Symptoms**: App crashes silently
**Solutions**:

- Check if all required native libraries are included
- Verify ProGuard rules don't remove needed classes
- Test with different target platforms

### 3. Network/Permission Issues

**Symptoms**: White screen on first launch
**Solutions**:

- Verify internet permission in AndroidManifest.xml
- Check if device can reach Firebase servers
- Test with mobile data vs WiFi

### 4. Service Initialization Failures

**Symptoms**: App starts but shows white screen
**Solutions**:

- ✅ Added individual service error handling
- ✅ Services now fail gracefully
- ✅ App continues even if services fail

## 📱 TESTING CHECKLIST

### Device Testing

- [ ] Install debug APK (`main_debug.dart`)
- [ ] Check if basic Flutter app works
- [ ] Install full APK with enhanced debugging
- [ ] Check device logs during app launch
- [ ] Test with different network conditions

### Build Variants

- [ ] Test debug build: `flutter build apk --debug`
- [ ] Test profile build: `flutter build apk --profile`
- [ ] Test release build: `flutter build apk --release`

### Network Testing

- [ ] Test with WiFi connection
- [ ] Test with mobile data
- [ ] Test offline behavior
- [ ] Test in airplane mode

## 🔍 DIAGNOSTIC COMMANDS

### 1. Build Debug APK

```bash
flutter build apk --release -t lib/main_debug.dart --target-platform android-arm64
```

### 2. Build Enhanced Debug APK

```bash
flutter build apk --release --target-platform android-arm64
```

### 3. Check Device Logs

```bash
# Install ADB if not available
# Connect device via USB with debugging enabled
adb logcat -s flutter
```

### 4. Test Network Connectivity

```bash
# Test if device can reach Firebase
adb shell ping firebase.googleapis.com
```

## 📊 EXPECTED RESULTS

### Debug APK (main_debug.dart)

- **Should show**: Green checkmark with "App is working!" message
- **If this fails**: Basic Flutter setup issue

### Enhanced Debug APK (main.dart)

- **Should show**: Loading screen, then login/onboarding
- **If white screen**: Check logs for specific error
- **If error screen**: Shows specific error message

## 🎯 NEXT STEPS

### If Debug APK Works

1. Issue is in Firebase/service initialization
2. Check network connectivity
3. Review Firebase configuration
4. Check service dependencies

### If Debug APK Fails

1. Basic Flutter framework issue
2. Check device compatibility
3. Try different target platform
4. Check APK signing

### If Both Fail

1. Device-specific issue
2. Try different device
3. Check Android version compatibility
4. Review build configuration

## 🔧 QUICK FIXES TO TRY

### 1. Clear App Data

```bash
adb shell pm clear com.example.resume_builder_app
```

### 2. Reinstall APK

```bash
adb uninstall com.example.resume_builder_app
adb install -r app-release.apk
```

### 3. Check Permissions

```bash
adb shell dumpsys package com.example.resume_builder_app | grep permission
```

## 📞 IF STILL WHITE SCREEN

1. **Install debug APK first**: `flutter build apk --release -t lib/main_debug.dart`
2. **Check device logs**: `adb logcat -s flutter`
3. **Test network**: Ensure Firebase can be reached
4. **Try different device**: Test on another Android device
5. **Check build logs**: Look for warnings during APK build

---

**Current Status**: 🔧 Enhanced debugging implemented, ready for testing
**Next Action**: Install debug APK and check device logs
