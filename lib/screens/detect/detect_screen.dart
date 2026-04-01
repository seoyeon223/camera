import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/info_section_card.dart';
import '../../widgets/risk_badge.dart';

class DetectScreen extends StatelessWidget {
  const DetectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final suspiciousSignals = [
      {
        'name': 'CAM_ROOM_01',
        'type': 'Wi-Fi',
        'reason': '촬영기기 추정 키워드 포함',
        'risk': RiskLevel.high,
      },
      {
        'name': 'BT-SPY-02',
        'type': 'Bluetooth',
        'reason': '의심 숫자 조합 및 비정상 장치명',
        'risk': RiskLevel.medium,
      },
      {
        'name': 'Hidden_Device',
        'type': 'Wi-Fi',
        'reason': '의미 불명 긴 문자열 패턴',
        'risk': RiskLevel.medium,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('탐지 기능'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '주변 무선 신호 및 하드웨어 탐지',
                    style: AppTextStyles.title,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Wi-Fi, 블루투스, RF 신호, 렌즈 반사 결과를 기반으로 의심 신호를 표시합니다.',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('더미 탐지를 실행했습니다.'),
                    ),
                  );
                },
                icon: const Icon(Icons.radar),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    '탐지 시작',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        label: '의심 신호',
                        value: '${suspiciousSignals.length}개',
                        icon: Icons.wifi_tethering_error_rounded,
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'RF 반응',
                        value: '1건',
                        icon: Icons.sensors,
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: '렌즈 반사',
                        value: '주의',
                        icon: Icons.remove_red_eye_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            InfoSectionCard(
              title: 'Wi-Fi / 블루투스 탐지 결과',
              subtitle: '의심 키워드와 패턴을 기반으로 분류한 더미 결과입니다.',
              icon: Icons.wifi,
              child: Column(
                children: suspiciousSignals.map((signal) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SuspiciousSignalTile(
                      name: signal['name'] as String,
                      type: signal['type'] as String,
                      reason: signal['reason'] as String,
                      risk: signal['risk'] as RiskLevel,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            InfoSectionCard(
              title: '하드웨어 탐지 결과',
              subtitle: '외부 장비 연동 전, 발표용 더미 상태 화면입니다.',
              icon: Icons.memory,
              child: Column(
                children: const [
                  _HardwareResultCard(
                    title: 'RF 신호 수신 분석',
                    status: '의심 반응 감지',
                    description: '특정 구역에서 비정상적인 무선 반응이 1회 감지되었습니다.',
                    risk: RiskLevel.high,
                  ),
                  SizedBox(height: 12),
                  _HardwareResultCard(
                    title: '렌즈 반사 탐지',
                    status: '주의 필요',
                    description: '반사 패턴이 포착되었으나 추가 확인이 필요합니다.',
                    risk: RiskLevel.medium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '탐지 결과는 참고용이며, 주변 공유기나 정상 블루투스 기기 때문에 오탐이 발생할 수 있습니다. 의심 장치 발견 시 즉시 시설 관리자 또는 경찰에 신고하세요.',
                        style: AppTextStyles.body.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SuspiciousSignalTile extends StatelessWidget {
  final String name;
  final String type;
  final String reason;
  final RiskLevel risk;

  const _SuspiciousSignalTile({
    required this.name,
    required this.type,
    required this.reason,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              type[0],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.subtitle),
                const SizedBox(height: 4),
                Text(
                  '$type • $reason',
                  style: AppTextStyles.caption.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          RiskBadge(level: risk),
        ],
      ),
    );
  }
}

class _HardwareResultCard extends StatelessWidget {
  final String title;
  final String status;
  final String description;
  final RiskLevel risk;

  const _HardwareResultCard({
    required this.title,
    required this.status,
    required this.description,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: AppTextStyles.subtitle),
              ),
              RiskBadge(level: risk),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppTextStyles.caption.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}