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
              // 🚀 새롭게 만든 안전 점검 관리 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminSafetyInspectionScreen()),
              );
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

// 📋 공용 데이터 리스트 확인 화면
class AdminDataListScreen extends StatelessWidget {
  final String collection;
  final String title;

  const AdminDataListScreen({super.key, required this.collection, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot>(
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

              String itemTitle = collection == 'reports' 
                  ? '[${data['type'] ?? '일반제보'}]' 
                  : '[${data['store_type'] ?? '업종미상'}] ${data['store_name'] ?? '상호명 없음'}';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminDataDetailScreen(
                          collection: collection,
                          docId: docId,
                          title: itemTitle,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(itemTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text(
                                data['location_detail'] ?? data['address'] ?? "위치 정보 없음",
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status, 
                            style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    ),
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

// 🔍 개별 항목 상세 내용 및 사진 확인 화면
class AdminDataDetailScreen extends StatelessWidget {
  final String collection;
  final String docId;
  final String title;

  const AdminDataDetailScreen({
    super.key,
    required this.collection,
    required this.docId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상세 내용 확인')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).doc(docId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('데이터를 불러오지 못했습니다.'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text('문서를 찾을 수 없습니다.'));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String status = data['status'] ?? '대기중';

          // 🛠️ 사진 데이터를 안전하게 가져오도록 로직 강화
          List<String> images = [];
          if (data['imageUrls'] != null && data['imageUrls'] is List) {
            images.addAll(List<String>.from(data['imageUrls']));
          }
          if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
            images.add(data['imageUrl'].toString());
          }
          if (data['image'] != null && data['image'].toString().isNotEmpty) {
            images.add(data['image'].toString());
          }
          
          // 중복 URL 제거
          images = images.toSet().toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images.isNotEmpty) ...[
                  const Text('첨부된 사진', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade200,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              // 사진을 불러오지 못했을 때 보여줄 화면
                              errorBuilder: (context, error, stackTrace) => const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('이미지를 불러올 수 없습니다', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (images.length > 1) 
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('옆으로 밀어서 사진 확인 (${images.length}장)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ),
                  const SizedBox(height: 24),
                ] else ...[
                  // 첨부된 사진이 없을 때
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('첨부된 사진이 없습니다.', style: TextStyle(color: Colors.grey))),
                  ),
                  const SizedBox(height: 24),
                ],

                const Text('상세 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: data.entries.map((entry) {
                      if (['imageUrls', 'imageUrl', 'image', 'status'].contains(entry.key)) return const SizedBox.shrink();
                      return _buildDetailRow(entry.key, entry.value);
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 30),

                const Text('상태 처리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('현재 상태', style: TextStyle(fontSize: 16)),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: ['대기중', '승인완료', '반려됨'].contains(status) ? status : '대기중',
                          items: ['대기중', '승인완료', '반려됨'].map((s) {
                            return DropdownMenuItem(
                              value: s, 
                              child: Text(s, style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(s)))
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              FirebaseFirestore.instance.collection(collection).doc(docId).update({'status': newValue});
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$newValue(으)로 상태가 변경되었습니다.')));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String key, dynamic value) {
    final Map<String, String> keyTitles = {
      'type': '분류',
      'store_type': '업종',
      'store_name': '상호명',
      'address': '주소',
      'location_detail': '상세 위치',
      'other_reason': '상세/기타 내용',
      'createdAt': '등록일',
      'userId': '요청자 ID',
    };

    String displayKey = keyTitles[key] ?? key;
    String displayValue = value is Timestamp ? value.toDate().toString().split('.').first : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(displayKey, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(displayValue, style: const TextStyle(fontSize: 15))),
        ],
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

// 🛡️ [신규 추가] 안전 점검 데이터 관리 화면 (대략적인 기능 구현)
class AdminSafetyInspectionScreen extends StatefulWidget {
  const AdminSafetyInspectionScreen({super.key});

  @override
  State<AdminSafetyInspectionScreen> createState() => _AdminSafetyInspectionScreenState();
}

class _AdminSafetyInspectionScreenState extends State<AdminSafetyInspectionScreen> {
  // 더미 데이터 리스트
  final List<Map<String, dynamic>> _inspections = [
    {'id': '1', 'name': '강남역 1번 출구 공중화장실', 'lastDate': '2023-10-20', 'status': '정상'},
    {'id': '2', 'name': '역삼동 스타벅스 화장실', 'lastDate': '2023-09-15', 'status': '점검요망'},
    {'id': '3', 'name': '코엑스 몰 B1 화장실', 'lastDate': '2023-10-24', 'status': '정상'},
    {'id': '4', 'name': '서울역 대합실 화장실', 'lastDate': '2023-08-01', 'status': '점검요망'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('안전 점검 데이터 관리'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _inspections.length,
        itemBuilder: (context, index) {
          final item = _inspections[index];
          final bool isNormal = item['status'] == '정상';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isNormal ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(
                  isNormal ? Icons.check_circle : Icons.warning_rounded,
                  color: isNormal ? Colors.green : Colors.red,
                ),
              ),
              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('최근 점검일: ${item['lastDate']}'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNormal ? Colors.grey.shade200 : Colors.blue,
                  foregroundColor: isNormal ? Colors.black87 : Colors.white,
                  elevation: 0,
                ),
                onPressed: () {
                  // 상태 변경 로직
                  setState(() {
                    _inspections[index]['status'] = isNormal ? '점검요망' : '정상';
                    // 점검요망 -> 정상으로 바꿀 때 날짜를 오늘로 갱신
                    if (!isNormal) {
                      _inspections[index]['lastDate'] = DateTime.now().toString().split(' ')[0];
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item['name']} 상태가 변경되었습니다.')),
                  );
                },
                child: Text(isNormal ? '점검필요 처리' : '점검완료'),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('새 점검 장소 추가 기능은 준비 중입니다.')));
        },
        icon: const Icon(Icons.add),
        label: const Text('장소 추가'),
      ),
    );
  }
}