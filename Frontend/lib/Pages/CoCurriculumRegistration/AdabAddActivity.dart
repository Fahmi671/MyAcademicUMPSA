import 'package:flutter/material.dart';

class AdabAddActivity extends StatelessWidget {
  const AdabAddActivity({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF3F8F3F);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Co-Curriculum Management',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Text(
          'Add Activity Page',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}