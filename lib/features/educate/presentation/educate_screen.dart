import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../premium/data/premium_access_repository.dart';
import '../../premium/presentation/widgets/premium_badge.dart';
import '../data/lesson_repository.dart';
import '../domain/lesson.dart';
import '../domain/lesson_track.dart';
import 'lesson_detail_screen.dart';

class EducateScreen extends StatelessWidget {
  const EducateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = LessonRepository();
    final tracks = repository.getTracks();
    final premiumRepository = PremiumAccessRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Educate Me')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Learn the pattern.', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'This section explains why the cycle happens and what you may actually be chasing underneath it.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final track in tracks) ...[
            _TrackCard(track: track),
            const SizedBox(height: AppSpacing.md),
          ],
          FutureBuilder(
            future: premiumRepository.getStatus(),
            builder: (context, snapshot) {
              final status = snapshot.data;
              if (status == null || !status.showUpgradePrompts) {
                return const SizedBox.shrink();
              }

              return InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text('Educate Me Plus', style: AppTypography.section),
                        SizedBox(width: 8),
                        PremiumBadge(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Go deeper into compulsive patterns, emotional drivers, and advanced learning tracks.',
                      style: AppTypography.muted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, RouteNames.premium),
                        icon: const Icon(Icons.workspace_premium_outlined),
                        label: Text(status.isUnlocked ? 'Premium Active' : 'Explore Premium'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
              break;
            case 4:
              Navigator.pushReplacementNamed(context, RouteNames.support);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final LessonTrack track;

  const _TrackCard({
    required this.track,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(track.title, style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(track.subtitle, style: AppTypography.muted),
          const SizedBox(height: AppSpacing.md),
          for (final lesson in track.lessons) ...[
            _LessonTile(lesson: lesson),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;

  const _LessonTile({
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(lesson.title),
      subtitle: Text(lesson.summary),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailScreen(lesson: lesson),
          ),
        );
      },
    );
  }
}
