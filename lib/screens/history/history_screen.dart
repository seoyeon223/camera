import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('활동 기록'),
      ),
      body: const Center(
        child: Text('기록 화면'),
      ),
    );
  }
}