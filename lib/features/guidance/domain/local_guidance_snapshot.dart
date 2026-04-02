class LocalGuidanceSnapshot {
  final bool isUnlocked;
  final String title;
  final String body;
  final String actionLine;
  final String packLabel;
  final String footerLine;

  const LocalGuidanceSnapshot({
    required this.isUnlocked,
    required this.title,
    required this.body,
    required this.actionLine,
    required this.packLabel,
    required this.footerLine,
  });

  factory LocalGuidanceSnapshot.locked() {
    return const LocalGuidanceSnapshot(
      isUnlocked: false,
      title: 'Local Premium Guidance',
      body:
          'Breakout Plus includes curated local guidance and faith-sensitive packs without AI chat.',
      actionLine: 'Upgrade to Breakout Plus to unlock premium local guidance.',
      packLabel: 'Locked',
      footerLine: 'You can still use the core app without AI.',
    );
  }
}
