#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-12 educate scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/educate/domain \
  lib/features/educate/data \
  lib/features/educate/presentation \
  tools

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const moodLog = '/log/mood';
  static const cycleStageLog = '/log/cycle-stage';
  static const insights = '/insights';
  static const educate = '/educate';
  static const educateLesson = '/educate/lesson';
  static const support = '/support';
  static const cycle = '/cycle';
  static const privacySettings = '/privacy';
}
EOD

cat > lib/features/educate/domain/lesson.dart <<'EOD'
class Lesson {
  final String id;
  final String title;
  final String summary;
  final List<String> bullets;
  final String closingLine;

  const Lesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.bullets,
    required this.closingLine,
  });
}
EOD

cat > lib/features/educate/domain/lesson_track.dart <<'EOD'
import 'lesson.dart';

class LessonTrack {
  final String id;
  final String title;
  final String subtitle;
  final List<Lesson> lessons;

  const LessonTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.lessons,
  });
}
EOD

cat > lib/features/educate/data/lesson_repository.dart <<'EOD'
import '../domain/lesson.dart';
import '../domain/lesson_track.dart';

class LessonRepository {
  static const List<LessonTrack> _tracks = <LessonTrack>[
    LessonTrack(
      id: 'why_this_happens',
      title: 'Why This Happens',
      subtitle: 'Understand why urges can feel stronger than your intentions.',
      lessons: <Lesson>[
        Lesson(
          id: 'urge_is_a_wave',
          title: 'An urge is a wave, not a command',
          summary:
              'Urges often arrive with a false sense of urgency. They rise, peak, and fall.',
          bullets: <String>[
            'The body can confuse intensity with necessity.',
            'An urge can feel urgent without being important.',
            'Delay and interruption often reduce power fast.',
          ],
          closingLine:
              'The goal is not to panic at the wave. It is to outlast it.',
        ),
        Lesson(
          id: 'stress_and_escape',
          title: 'Stress often drives escape, not desire',
          summary:
              'Many acting-out moments are driven less by attraction and more by pressure, fatigue, or overwhelm.',
          bullets: <String>[
            'Stress reduces your willingness to tolerate discomfort.',
            'Escaping quickly can feel more attractive than coping well.',
            'The brain starts linking relief with a specific ritual.',
          ],
          closingLine:
              'When you name stress honestly, the cycle becomes easier to interrupt.',
        ),
      ],
    ),
    LessonTrack(
      id: 'what_am_i_chasing',
      title: 'What Am I Actually Chasing?',
      subtitle: 'Look beneath the habit and identify the payoff you are seeking.',
      lessons: <Lesson>[
        Lesson(
          id: 'relief_not_just_pleasure',
          title: 'Sometimes you are chasing relief, not pleasure',
          summary:
              'What looks like desire can actually be a search for relief, numbing, distraction, or comfort.',
          bullets: <String>[
            'Relief can masquerade as excitement.',
            'The ritual may promise calm more than pleasure.',
            'If the goal is relief, better relief tools can weaken the loop.',
          ],
          closingLine:
              'Ask what problem you are trying to solve in the moment.',
        ),
        Lesson(
          id: 'novelty_and_control',
          title: 'Novelty can feel like control',
          summary:
              'A flood of stimulation can create the illusion of control, power, or certainty for a short time.',
          bullets: <String>[
            'Novelty grabs attention fast and overwhelms reflection.',
            'More stimulation can become necessary to get the same effect.',
            'That pattern can leave you feeling flatter afterward.',
          ],
          closingLine:
              'The more clearly you see the payoff, the less mystical the habit becomes.',
        ),
      ],
    ),
    LessonTrack(
      id: 'recovery_and_rewiring',
      title: 'Recovery and Rewiring',
      subtitle: 'Learn how repetition, honesty, and interruption change the cycle.',
      lessons: <Lesson>[
        Lesson(
          id: 'earlier_interruptions',
          title: 'Earlier interruptions matter most',
          summary:
              'The fastest wins usually happen before the cycle reaches full speed.',
          bullets: <String>[
            'Catching boredom or loneliness early is easier than stopping at peak urge.',
            'Logs create awareness. Awareness creates earlier action.',
            'Small interruptions repeated often reshape the pattern.',
          ],
          closingLine:
              'You do not need perfect days. You need earlier catches.',
        ),
        Lesson(
          id: 'shame_vs_honesty',
          title: 'Shame hides patterns. Honesty reveals them.',
          summary:
              'Shame makes the habit feel darker and more personal. Honest tracking makes it more visible and workable.',
          bullets: <String>[
            'Shame says “this is who I am.”',
            'Honesty says “this is a pattern I can learn.”',
            'Patterns that can be seen can be changed.',
          ],
          closingLine:
              'Clear data and honest reflection are recovery tools, not punishments.',
        ),
      ],
    ),
  ];

  List<LessonTrack> getTracks() => _tracks;

  Lesson? findLessonById(String id) {
    for (final track in _tracks) {
      for (final lesson in track.lessons) {
        if (lesson.id == id) {
          return lesson;
        }
      }
    }
    return null;
  }
}
EOD
cat > lib/features/educate/presentation/lesson_detail_screen.dart <<'EOD'
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
EOD

cat > lib/features/educate/presentation/educate_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
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
EOD
cat > lib/app/app_router.dart <<'EOD'
import 'package:flutter/material.dart';

import '../core/constants/route_names.dart';
import '../features/cycle/domain/cycle_stage.dart';
import '../features/cycle/presentation/cycle_screen.dart';
import '../features/educate/presentation/educate_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/log/presentation/cycle_stage_log_screen.dart';
import '../features/log/presentation/log_hub_screen.dart';
import '../features/log/presentation/mood_log_screen.dart';
import '../features/onboarding/presentation/home_entry_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/privacy/domain/lock_scope.dart';
import '../features/privacy/presentation/privacy_settings_screen.dart';
import '../features/privacy/presentation/protected_route_gate.dart';
import '../features/rescue/presentation/rescue_screen.dart';
import '../features/support/presentation/support_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return MaterialPageRoute(
          builder: (_) => const HomeEntryScreen(),
        );
      case RouteNames.onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
      case RouteNames.rescue:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            isRescueRoute: true,
            child: RescueScreen(),
          ),
        );
      case RouteNames.cycle:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.cycle,
            child: CycleScreen(),
          ),
        );
      case RouteNames.logHub:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.logs,
            child: LogHubScreen(),
          ),
        );
      case RouteNames.moodLog:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.logs,
            child: MoodLogScreen(),
          ),
        );
      case RouteNames.cycleStageLog:
        final stage = settings.arguments is CycleStage
            ? settings.arguments as CycleStage
            : CycleStage.triggers;
        return MaterialPageRoute(
          builder: (_) => ProtectedRouteGate(
            scope: LockScope.logs,
            child: CycleStageLogScreen(initialStage: stage),
          ),
        );
      case RouteNames.insights:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.insights,
            child: InsightsScreen(),
          ),
        );
      case RouteNames.educate:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            child: EducateScreen(),
          ),
        );
      case RouteNames.support:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.support,
            child: SupportScreen(),
          ),
        );
      case RouteNames.privacySettings:
        return MaterialPageRoute(
          builder: (_) => const ProtectedRouteGate(
            scope: LockScope.app,
            child: PrivacySettingsScreen(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeEntryScreen(),
        );
    }
  }
}
EOD

cat > tools/verify_ba12.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/core/constants/route_names.dart',
    'lib/features/educate/domain/lesson.dart',
    'lib/features/educate/domain/lesson_track.dart',
    'lib/features/educate/data/lesson_repository.dart',
    'lib/features/educate/presentation/educate_screen.dart',
    'lib/features/educate/presentation/lesson_detail_screen.dart',
    'lib/app/app_router.dart',
]

REQUIRED_TEXT = {
    'lib/core/constants/route_names.dart': "static const educate = '/educate';",
    'lib/features/educate/domain/lesson.dart': 'class Lesson',
    'lib/features/educate/domain/lesson_track.dart': 'class LessonTrack',
    'lib/features/educate/data/lesson_repository.dart': 'class LessonRepository',
    'lib/features/educate/presentation/educate_screen.dart': 'Educate Me',
    'lib/features/educate/presentation/lesson_detail_screen.dart': 'Takeaway',
    'lib/app/app_router.dart': 'case RouteNames.educate:',
}

def main() -> int:
    root = Path.cwd()

    missing = [path for path in REQUIRED if not (root / path).exists()]
    if missing:
        print('Missing files:')
        for item in missing:
            print(f' - {item}')
        return 1

    bad = []
    for path, needle in REQUIRED_TEXT.items():
        text = (root / path).read_text(encoding='utf-8')
        if needle not in text:
            bad.append((path, needle))

    if bad:
        print('Content checks failed:')
        for path, needle in bad:
            print(f' - {path} missing: {needle}')
        return 1

    print('Breakout Addiction BA-12 educate verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-12 educate scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba12.py
