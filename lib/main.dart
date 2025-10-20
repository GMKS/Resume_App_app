import 'package:flutter/material.dart';
import 'screens/enhanced_login_screen.dart';
import 'services/currency_service.dart';
import 'services/premium_service.dart';
import 'services/node_api_service.dart';
import 'services/resume_storage_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start app immediately for faster startup
  runApp(const MyApp());

  // Initialize services asynchronously in parallel after app starts
  _initializeServicesAsync();
}

/// Initialize all services in parallel to avoid blocking startup
void _initializeServicesAsync() {
  Future.wait([
        CurrencyService.initialize().catchError((e) {
          debugPrint('CurrencyService initialization failed: $e');
        }),
        PremiumService.initialize().catchError((e) {
          debugPrint('PremiumService initialization failed: $e');
        }),
        ApiService.init().catchError((e) {
          debugPrint('ApiService initialization failed: $e');
        }),
        ResumeStorageService.instance.initialize().catchError((e) {
          debugPrint('ResumeStorageService initialization failed: $e');
        }),
      ])
      .then((_) {
        debugPrint('All services initialized successfully');
      })
      .catchError((e) {
        debugPrint('Service initialization error: $e');
      });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clear all listeners
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Handle successful payment here
    debugPrint("Payment Successful: ${response.paymentId}");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Handle payment error here
    debugPrint("Payment Error: ${response.code} - ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet selection here
    debugPrint("External Wallet Selected: ${response.walletName}");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const EnhancedLoginScreen(),
    );
  }
}
