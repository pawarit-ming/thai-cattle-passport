import 'package:flutter/material.dart';

class BuyScreen extends StatelessWidget { // แก้ชื่อตรงนี้
  const BuyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy'),
      ),
      body: const Center(
        child: Text(
          'User Buy Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}