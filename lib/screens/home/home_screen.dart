import 'package:flutter/material.dart';
import '../../core/constants/route_names.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_menu_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final menus = [
      (
        '탐지 기능',
        'Wi-Fi, 블루투스, RF, 렌즈 반사 탐지 결과 확인',
        Icons.radar,
        RouteNames.detect,
      ),
      (
        '지도 및 위치',
        '주변 안전 장소와 점검 정보를 지도에서 확인',
        Icons.map,
        RouteNames.map,
      ),
      (
        '사용자 제보',
        '위험 장소 또는 의심 사례를 제보',
        Icons.report_problem_outlined,
        RouteNames.report,
      ),
      (
        '사용자 가이드',
        '탐지 절차와 체크리스트 확인',
        Icons.menu_book_outlined,
        RouteNames.guide,
      ),
      (
        '활동 기록',
        '최근 탐지 기록과 제보 내역 확인',
        Icons.history,
        RouteNames.history,
      ),
      (
        '업소 등록 신청',
        '업소 정보를 등록하고 관리자 승인을 요청',
        Icons.storefront_outlined,
        RouteNames.businessRegister,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safe Toilet Map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '안전 화장실 지도',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '안심하고 이용할 수 있는 공간 찾기',
                          style: AppTextStyles.title,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '탐지 기능, 지도 확인, 사용자 제보, 안전 가이드와 업소 등록 신청을 한곳에서 이용할 수 있는 통합 홈 화면입니다.',
                    style: AppTextStyles.body.copyWith(
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.radar,
                        label: '탐지',
                        colorScheme: colorScheme,
                      ),
                      _InfoChip(
                        icon: Icons.map_outlined,
                        label: '지도',
                        colorScheme: colorScheme,
                      ),
                      _InfoChip(
                        icon: Icons.report_outlined,
                        label: '제보',
                        colorScheme: colorScheme,
                      ),
                      _InfoChip(
                        icon: Icons.storefront_outlined,
                        label: '업소 등록',
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: menus.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index < menus.length) {
                    final menu = menus[index];
                    return AppMenuCard(
                      title: menu.$1,
                      subtitle: menu.$2,
                      icon: menu.$3,
                      onTap: () => Navigator.pushNamed(context, menu.$4),
                    );
                  }

                  return Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: colorScheme.primary,
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, RouteNames.adminLogin),
                      icon: const Icon(
                        Icons.lock_outline,
                        size: 16,
                      ),
                      label: const Text(
                        '관리자 페이지',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}