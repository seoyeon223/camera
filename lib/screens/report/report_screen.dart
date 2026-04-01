import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 제보'),
      ),
      body: const Center(
        child: Text('제보 화면'),
      ),
    );
  }
}