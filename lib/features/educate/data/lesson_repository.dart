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
