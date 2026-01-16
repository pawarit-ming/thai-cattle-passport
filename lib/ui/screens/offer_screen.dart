import 'package:flutter/material.dart';

class OfferScreen extends StatelessWidget { // แก้ชื่อตรงนี้
  const OfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offer'),
      ),
      body: const Center(
        child: Text(
          'User Offer Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}