// test_payment_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/datasources/payment_service.dart';
import '../blocs/payment/payment_bloc.dart';
import 'onboarding/models/payment_enums.dart';

class TestPaymentPage extends StatelessWidget {
  const TestPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Payment System Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Payment Methods: ${PaymentMethod.values.length}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Payment Statuses: ${PaymentStatus.values.length}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Test payment service
                final paymentService = context.read<PaymentService>();
                print('PaymentService initialized: ${paymentService.runtimeType}');
              },
              child: const Text('Test Payment Service'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Test payment bloc
                final paymentBloc = context.read<PaymentBloc>();
                print('PaymentBloc initialized: ${paymentBloc.runtimeType}');
              },
              child: const Text('Test Payment Bloc'),
            ),
          ],
        ),
      ),
    );
  }
}
