import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('관리자 페이지', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAdminCard(
            context,
            title: '제보 관리',
            subtitle: '사용자 제보 내용을 확인하고 처리',
            icon: Icons.report_gmailerrorred_rounded,
            color: Colors.redAccent,
            // 탭하면 제보 리스트 화면으로 이동
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminDataListScreen(collection: 'reports', title: '제보 관리')),
            ),
          ),
          const SizedBox(height: 16),
          _buildAdminCard(
            context,
            title: '업소 등록 요청',
            subtitle: '업소 측 등록 요청 승인 및 검토',
            icon: Icons.store_mall_directory_rounded,
            color: Colors.blueAccent,
            // 탭하면 업소 등록 리스트 화면으로 이동
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminDataListScreen(collection: 'businesses', title: '업소 등록 관리')),
            ),
          ),
          const SizedBox(height: 16),
          _buildAdminCard(
            context,
            title: '안전 점검 데이터 관리',
            subtitle: '점검 주기 및 상태 정보 수정',
            icon: Icons.fact_check_rounded,
            color: Colors.green,
            onTap: () {
              // 점검 데이터 관리 로직 추가 가능
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// 📋 공용 데이터 리스트 확인 및 상태 변경 화면
class AdminDataListScreen extends StatelessWidget {
  final String collection;
  final String title;

  const AdminDataListScreen({super.key, required this.collection, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot>(
        // Firestore에서 데이터를 최신순으로 실시간 감시
        stream: FirebaseFirestore.instance.collection(collection).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('데이터를 불러오지 못했습니다.'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('접수된 내역이 없습니다.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final String status = data['status'] ?? '대기중';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 이미지 표시 (이미지 URL이 있는 경우)
                      if (data['imageUrls'] != null || data['imageUrl'] != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data['imageUrl'] ?? (data['imageUrls'] as List).first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),

                      // 2. 텍스트 정보 표시
                      Text(
                        collection == 'reports' ? '[${data['type']}]' : '[${data['store_type']}] ${data['store_name']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('상세위치: ${data['location_detail'] ?? data['address'] ?? "정보 없음"}', style: const TextStyle(fontSize: 15)),
                      if (data['other_reason'] != null) ...[
                        const SizedBox(height: 4),
                        Text('제보내용: ${data['other_reason']}', style: TextStyle(color: Colors.grey.shade700)),
                      ],

                      const Divider(height: 24),

                      // 3. 상태 변경 드롭다운
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('처리 상태 변경', style: TextStyle(fontWeight: FontWeight.w600)),
                          DropdownButton<String>(
                            value: ['대기중', '승인완료', '반려됨'].contains(status) ? status : '대기중',
                            items: ['대기중', '승인완료', '반려됨'].map((s) {
                              return DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: _getStatusColor(s))));
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                // Firestore의 해당 문서 상태값을 즉시 업데이트
                                FirebaseFirestore.instance.collection(collection).doc(docId).update({'status': newValue});
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '승인완료': return Colors.green;
      case '반려됨': return Colors.red;
      default: return Colors.orange;
    }
  }
}