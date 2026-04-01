import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('안전 이용 가이드', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // 💡 상단 인사말
          const Text(
            '안심하고 이용하는 화장실,\n아래 수칙을 꼭 확인해 주세요!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 32),

          // 🔍 1. 공중 화장실 진입 시 매뉴얼
          _buildSectionTitle(Icons.search, '1. 공중 화장실 진입 시 확인 매뉴얼', Colors.blueAccent),
          const SizedBox(height: 16),
          _buildManualCard([
            '문, 벽, 천장에 수상한 구멍이 있는지 먼저 확인하세요. ',
            '휴지걸이, 나사못, 거울, 환풍기, 쓰레기통 등 주변 사물을 유심히 살펴보세요.',
            '칸막이 위/아래 틈새로 넘어오는 수상한 움직임이나 물체가 없는지 주의하세요.',
            '조명이 유난히 어둡거나, 불필요한 물건이 수상한 위치에 놓여있다면 조심하세요.(라이터, 볼펜, 보조배터리 등)',
            '본 앱의 탐지기능을 켰을 때, 수상한 와이파이나 블루투스 신호가 잡히는지 확인해 보세요.'
          ]),
          const SizedBox(height: 40),

          // 🚨 2. 발견 시 신고 매뉴얼
          _buildSectionTitle(Icons.warning_amber_rounded, '2. 불법촬영 의심/발견 시 대처 매뉴얼', Colors.redAccent),
          const SizedBox(height: 16),
          _buildManualCard([
            '절대 기기를 만지거나 훼손하지 마세요! 지문 등 경찰의 수사를 위한 증거 보존이 가장 중요합니다.',
            '즉시 해당 화장실 칸에서 빠져나와 밖으로 등 안전한 곳으로 이동하세요.',
            '직접적인 위협을 느끼거나 명백한 범죄 현장(또는 기기)을 발견한 경우, 즉시 112에 신고하여 경찰의 도움을 받으세요.',
            '다른 사람들을 위해 본 앱의 [안전 제보하기] 메뉴를 통해 현장 사진(선택)과 정확한 위치를 남겨주세요.'
          ]),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 🎨 소제목을 일관성 있게 그려주는 커스텀 위젯 함수
  Widget _buildSectionTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // 🎨 매뉴얼 리스트를 회색 박스(카드) 안에 예쁘게 그려주는 커스텀 위젯 함수
  Widget _buildManualCard(List<String> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((entry) {
          int index = entry.key + 1; // 1번부터 시작하도록 +1
          String text = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 숫자가 적힌 검은색 동그라미 뱃지
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.0),
                  ),
                ),
                const SizedBox(width: 12),
                // 매뉴얼 내용 텍스트
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
