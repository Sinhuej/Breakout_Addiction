import '../domain/demo_showcase_item.dart';

class DemoShowcaseRepository {
  const DemoShowcaseRepository();

  List<DemoShowcaseItem> getItems() {
    return const <DemoShowcaseItem>[
      DemoShowcaseItem(
        title: 'Private Recovery Core',
        subtitle:
            'The app is useful even with AI turned off and premium disabled.',
        bullets: <String>[
          'Cycle wheel, Rescue, logs, insights, support, and privacy are all real.',
          'The user can keep the app simple and local.',
          'Startup messaging lowers shame instead of increasing it.',
        ],
      ),
      DemoShowcaseItem(
        title: 'Breakout Plus Without AI',
        subtitle:
            'Premium stands on its own through local guidance and faith-sensitive packs.',
        bullets: <String>[
          'Local premium guidance is unlocked without AI chat.',
          'Faith-sensitive packs can stay local and private.',
          'Plus is valuable even for users who never want AI.',
        ],
      ),
      DemoShowcaseItem(
        title: 'Optional AI Layer',
        subtitle:
            'AI is clearly separated into Breakout Plus AI and can be turned off.',
        bullets: <String>[
          'AI mode clarity is visible on-screen.',
          'Usage meter shows local/stub/live activity honestly.',
          'Emergency fallback pushes users toward human help, not more chat.',
        ],
      ),
      DemoShowcaseItem(
        title: 'Proactive Interruption',
        subtitle:
            'The app can now actively help before risky moments begin.',
        bullets: <String>[
          'Risk windows are configurable.',
          'Live local reminders can be synced.',
          'Widget entry paths and quick actions support earlier interruption.',
        ],
      ),
    ];
  }
}
