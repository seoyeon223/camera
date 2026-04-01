import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 현재 접속 중인 사용자의 고유 ID(UID)를 가져옵니다.
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2, // 탭의 개수를 2개로 설정합니다.
      child: Scaffold(
        appBar: AppBar(
          title: const Text('내 활동 기록', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: [
              Tab(icon: Icon(Icons.warning_rounded), text: '제보 내역'),
              Tab(icon: Icon(Icons.storefront_rounded), text: '업소 등록 내역'),
            ],
          ),
        ),
        body: currentUid == null
            ? const Center(child: Text('로그인 정보가 없습니다.'))
            : TabBarView(
                children: [
                  // 첫 번째 탭: 제보 내역 리스트
                  _buildHistoryList(
                    collectionName: 'reports',
                    uidField: 'reporter_uid',
                    uid: currentUid,
                    icon: Icons.warning_rounded,
                    iconColor: Colors.redAccent,
                    titleField: 'type',
                    subtitleField: 'location_detail',
                    emptyMessage: '아직 제보한 내역이 없습니다.',
                  ),
                  // 두 번째 탭: 업소 등록 리스트
                  _buildHistoryList(
                    collectionName: 'businesses',
                    uidField: 'uploader_uid',
                    uid: currentUid,
                    icon: Icons.storefront_rounded,
                    iconColor: Colors.blueAccent,
                    titleField: 'store_name',
                    subtitleField: 'address',
                    emptyMessage: '아직 등록 신청한 업소가 없습니다.',
                  ),
                ],
              ),
      ),
    );
  }

  // 💡 리스트를 그려주는 재사용 가능한 위젯 함수 (StreamBuilder 사용)
  Widget _buildHistoryList({
    required String collectionName,
    required String uidField,
    required String uid,
    required IconData icon,
    required Color iconColor,
    required String titleField,
    required String subtitleField,
    required String emptyMessage,
  }) {
    return StreamBuilder<QuerySnapshot>(
      // Firestore에서 특정 컬렉션(reports 또는 businesses) 중 내 UID와 일치하는 문서만 실시간으로 가져옵니다.
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .where(uidField, isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        // 로딩 중일 때
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // 데이터가 없거나 에러가 났을 때
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(emptyMessage, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // 시간순 정렬 (최신 데이터가 위로 오도록)
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        // 결과 리스트 그리기
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            
            // 상태값 표시 (기본값: 심사중)
            final String status = data['status'] ?? '심사중';
            
            return Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(icon, color: iconColor),
                ),
                title: Text(data[titleField] ?? '이름 없음', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data[subtitleField] ?? '상세 정보 없음', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: _buildStatusBadge(status),
              ),
            );
          },
        );
      },
    );
  }

  // 🎨 상태(심사중, 승인, 반려)를 예쁜 뱃지 모양으로 만들어주는 함수
  Widget _buildStatusBadge(String status) {
    Color color;
    if (status == '승인완료') {
      color = Colors.green;
    } else if (status == '반려됨') {
      color = Colors.red;
    } else {
      color = Colors.orange; // 검토중, 심사중
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}