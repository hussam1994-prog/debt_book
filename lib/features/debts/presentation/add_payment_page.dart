import 'package:flutter/material.dart';

class AddPaymentPage extends StatelessWidget {
  final String debtId;
  const AddPaymentPage({super.key, required this.debtId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment')),
      body: const Center(child: Text('Add Payment Page')),
    );
  }
}