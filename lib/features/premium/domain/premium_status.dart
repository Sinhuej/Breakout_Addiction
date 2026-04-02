import 'premium_plan.dart';

class PremiumStatus {
  final PremiumPlan plan;
  final bool showUpgradePrompts;

  const PremiumStatus({
    required this.plan,
    required this.showUpgradePrompts,
  });

  factory PremiumStatus.defaults() {
    return const PremiumStatus(
      plan: PremiumPlan.none,
      showUpgradePrompts: true,
    );
  }

  PremiumStatus copyWith({
    PremiumPlan? plan,
    bool? showUpgradePrompts,
  }) {
    return PremiumStatus(
      plan: plan ?? this.plan,
      showUpgradePrompts: showUpgradePrompts ?? this.showUpgradePrompts,
    );
  }

  bool get isUnlocked => plan != PremiumPlan.none;
  bool get hasPremium => plan == PremiumPlan.plus || plan == PremiumPlan.plusAi;
  bool get hasAiPremium => plan == PremiumPlan.plusAi;
}
