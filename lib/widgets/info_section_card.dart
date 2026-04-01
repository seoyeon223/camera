import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';

class InfoSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final IconData icon;

  const InfoSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: AppTextStyles.subtitle),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: AppTextStyles.caption),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}