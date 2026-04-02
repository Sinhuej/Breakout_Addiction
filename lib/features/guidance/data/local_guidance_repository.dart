import '../domain/local_guidance_snapshot.dart';

class LocalGuidanceRepository {
  const LocalGuidanceRepository();

  LocalGuidanceSnapshot resetPack() {
    return const LocalGuidanceSnapshot(
      isUnlocked: true,
      title: 'Reset the Window Earlier',
      body:
          'A premium local pack for the moments when the pattern is just beginning. The goal is not to win a huge battle. The goal is to shorten the window where the ritual can grow.',
      actionLine:
          'Stand up, change rooms, and do one physical interruption before you negotiate with yourself.',
      packLabel: 'Breakout Plus Pack',
      footerLine:
          'Local guidance stays available even if you never use AI.',
    );
  }

  LocalGuidanceSnapshot stressPack() {
    return const LocalGuidanceSnapshot(
      isUnlocked: true,
      title: 'Pressure Is Not the Same as Desire',
      body:
          'When stress is high, the habit can masquerade as relief. This pack helps you treat pressure as pressure instead of mislabeling it as desire.',
      actionLine:
          'Name the pressure honestly, lower stimulation, and do one body-level reset before you make any private decision.',
      packLabel: 'Pressure Reset Pack',
      footerLine:
          'Strong premium guidance does not have to depend on AI.',
    );
  }

  LocalGuidanceSnapshot lonelinessPack() {
    return const LocalGuidanceSnapshot(
      isUnlocked: true,
      title: 'Break Isolation Fast',
      body:
          'Loneliness can make the ritual feel like comfort. This pack is built to move you toward connection, visibility, and interruption before the urge gains speed.',
      actionLine:
          'Use one human-contact move now: text someone, leave the room, or move into a less isolated setting.',
      packLabel: 'Connection Pack',
      footerLine:
          'Local premium packs can still feel personal when they are pattern-aware.',
    );
  }

  LocalGuidanceSnapshot boredomPack() {
    return const LocalGuidanceSnapshot(
      isUnlocked: true,
      title: 'Boredom Loves an Empty Loop',
      body:
          'Boredom often creates the quiet setup that lets the cycle start. This pack helps you replace low-friction drift with structured movement.',
      actionLine:
          'Create friction quickly: leave the phone, switch locations, and choose a short active task with a visible finish line.',
      packLabel: 'Momentum Pack',
      footerLine:
          'Premium local guidance can be simple, direct, and effective.',
    );
  }

  LocalGuidanceSnapshot faithPack(String religion) {
    if (religion == 'Christian') {
      return const LocalGuidanceSnapshot(
        isUnlocked: true,
        title: 'Grace Is Still Here',
        body:
            'Grace is not gone because the day got hard. This pack is built for the moments when shame tries to convince you to withdraw instead of return.',
        actionLine:
            'Come back to honesty, take one clean next step, and remember that falling into shame is not the same as moving toward healing.',
        packLabel: 'Christian Faith Pack',
        footerLine:
            'This is a local faith-sensitive pack. It does not require AI chat.',
      );
    }

    return const LocalGuidanceSnapshot(
      isUnlocked: true,
      title: 'Return to What Is Good',
      body:
          'This faith-sensitive pack is designed to help you slow down, remember your values, and move toward peace instead of secrecy.',
      actionLine:
          'Pause, breathe, and choose the next action that matches the person you want to become.',
      packLabel: 'Faith-Sensitive Pack',
      footerLine:
          'Faith-sensitive premium packs can stay local and private.',
    );
  }
}
