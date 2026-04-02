enum PremiumPlan {
  none,
  plus,
  plusAi,
}

extension PremiumPlanX on PremiumPlan {
  String get label {
    switch (this) {
      case PremiumPlan.none:
        return 'Free';
      case PremiumPlan.plus:
        return 'Breakout Plus';
      case PremiumPlan.plusAi:
        return 'Breakout Plus AI';
    }
  }

  String get subtitle {
    switch (this) {
      case PremiumPlan.none:
        return 'Core recovery tools only.';
      case PremiumPlan.plus:
        return 'Private, powerful, no AI required.';
      case PremiumPlan.plusAi:
        return 'Everything in Plus, with optional AI guidance and chat.';
    }
  }
}
