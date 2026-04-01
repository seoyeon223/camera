import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 페이지'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdminCard(
            title: '제보 관리',
            subtitle: '사용자 제보 내용을 확인하고 처리',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: '업소 등록 요청',
            subtitle: '업소 측 등록 요청 승인 및 검토',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            title: '안전 점검 데이터 관리',
            subtitle: '점검 주기 및 상태 정보 수정',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withValues(alpha: 0.06),
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}