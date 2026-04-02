class PremiumStatus {
  final bool isUnlocked;
  final bool showUpgradePrompts;

  const PremiumStatus({
    required this.isUnlocked,
    required this.showUpgradePrompts,
  });

  factory PremiumStatus.defaults() {
    return const PremiumStatus(
      isUnlocked: false,
      showUpgradePrompts: true,
    );
  }

  PremiumStatus copyWith({
    bool? isUnlocked,
    bool? showUpgradePrompts,
  }) {
    return PremiumStatus(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      showUpgradePrompts: showUpgradePrompts ?? this.showUpgradePrompts,
    );
  }
}
