import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 가이드'),
      ),
      body: const Center(
        child: Text('가이드 화면'),
      ),
    );
  }
}