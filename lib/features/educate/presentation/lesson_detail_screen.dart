import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../domain/lesson.dart';

class LessonDetailScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(lesson.title, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Text(lesson.summary, style: AppTypography.body),
          const SizedBox(height: AppSpacing.lg),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Key Points', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                for (final bullet in lesson.bullets) ...[
                  Text('• $bullet', style: AppTypography.body),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Takeaway', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text(lesson.closingLine, style: AppTypography.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
