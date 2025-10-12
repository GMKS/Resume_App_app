import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'package:Resume_App_app/services/upi_payment_service.dart';

// Generate mocks
@GenerateMocks([http.Client])
void main() {
  group('UpiPaymentService Tests', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test_token_123',
      });
    });

    group('UPI App Management', () {
      test('should return correct UPI app details', () {
        final googlePayDetails = UpiPaymentService.getUpiAppDetails('googlepay');
        expect(googlePayDetails, isNotNull);
        expect(googlePayDetails!['name'], 'Google Pay');
        expect(googlePayDetails['package'], 'com.google.android.apps.nbu.paisa.user');
        expect(googlePayDetails['color'], '4285F4');
      });

      test('should return null for invalid UPI app', () {
        final invalidApp = UpiPaymentService.getUpiAppDetails('invalidapp');
        expect(invalidApp, isNull);
      });
    });

    group('UPI Payment Intent Creation', () {
      test('should create UPI payment intent successfully', () async {
        when(mockClient.post(any, body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(
            '''
            {
              "success": true,
              "data": {
                "paymentData": {
                  "orderId": "order_test_123",
                  "amount": 29900,
                  "currency": "INR",
                  "key": "rzp_test_key"
                },
                "upiApp": "googlepay",
                "paymentMethod": "upi"
              }
            }
            ''',
            200,
          ),
        );

        final result = await UpiPaymentService.createUpiPaymentIntent(
          planType: 'monthly',
          upiApp: 'googlepay',
          currency: 'INR',
          client: mockClient,
        );

        expect(result, isNotNull);
        expect(result['success'], true);
        expect(result['data']['paymentData']['orderId'], 'order_test_123');
      });

      test('should handle invalid plan types', () async {
        try {
          await UpiPaymentService.createUpiPaymentIntent(
            planType: 'invalid',
            upiApp: 'googlepay',
            currency: 'INR',
          );
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e.toString(), contains('Invalid plan type'));
        }
      });
    });

    group('UPI Payment Verification', () {
      test('should verify UPI payment with correct parameters', () async {
        when(mockClient.post(any, body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(
            '''
            {
              "success": true,
              "message": "Payment verified successfully"
            }
            ''',
            200,
          ),
        );

        final result = await UpiPaymentService.verifyUpiPayment(
          planType: 'monthly',
          amount: 299.0,
          currency: 'INR',
          razorpayPaymentId: 'pay_test_123',
          razorpayOrderId: 'order_test_123',
          razorpaySignature: 'signature_test_123',
          client: mockClient,
        );

        expect(result, isNotNull);
        expect(result['success'], true);
        expect(result['message'], 'Payment verified successfully');
      });

      test('should handle verification failure gracefully', () async {
        when(mockClient.post(any, body: anyNamed('body'))).thenAnswer(
          (_) async => http.Response(
            '''
            {
              "success": false,
              "message": "Verification failed"
            }
            ''',
            400,
          ),
        );

        final result = await UpiPaymentService.verifyUpiPayment(
          planType: 'monthly',
          amount: 299.0,
          currency: 'INR',
          razorpayPaymentId: 'pay_test_123',
          razorpayOrderId: 'order_test_123',
          razorpaySignature: 'signature_test_123',
          client: mockClient,
        );

        expect(result, isNotNull);
        expect(result['success'], false);
        expect(result['message'], 'Verification failed');
      });
    });

    group('UPI Payment Widget Creation', () {
      testWidgets('should create UPI payment button widget', (WidgetTester tester) async {
        bool paymentStarted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return UpiPaymentService.createUpiPaymentButton(
                    context: context,
                    planType: 'monthly',
                    amount: 299.0,
                    onPaymentStart: () {
                      paymentStarted = true;
                    },
                    onPaymentSuccess: (_) {},
                    onPaymentError: (_) {},
                  );
                },
              ),
            ),
          ),
        );

        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(paymentStarted, isFalse);

        await tester.tap(find.byType(ElevatedButton));
        expect(paymentStarted, isTrue);
      });

      testWidgets('should create UPI payment button widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => UpiPaymentService.createUpiPaymentButton(
                  context: context,
                  planType: 'monthly',
                  amount: 299.0,
                  onPaymentStart: () {},
                  onPaymentSuccess: (_) {},
                  onPaymentError: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('Pay ₹299 with UPI'), findsOneWidget);
        expect(find.byIcon(Icons.payment), findsOneWidget);
      });
    });
  });
}

// Helper widgets for testing
import 'package:flutter/material.dart';

class TestUpiPaymentWidget extends StatelessWidget {
  const TestUpiPaymentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return UpiPaymentService.createUpiPaymentButton(
      context: context,
      planType: 'monthly',
      amount: 299.0,
      onPaymentStart: () {},
      onPaymentSuccess: (result) {},
      onPaymentError: (error) {},
    );
  }
}