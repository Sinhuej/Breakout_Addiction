import 'package:shared_preferences/shared_preferences.dart';

import '../domain/premium_plan.dart';
import '../domain/premium_status.dart';

class PremiumAccessRepository {
  static const String _premiumPlanKey = 'premium_plan';
  static const String _legacyPremiumUnlockedKey = 'premium_unlocked';
  static const String _upgradePromptsKey = 'premium_upgrade_prompts';

  Future<PremiumStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final rawPlan = prefs.getString(_premiumPlanKey);
    final legacyUnlocked = prefs.getBool(_legacyPremiumUnlockedKey) ?? false;

    final PremiumPlan plan;
    if (rawPlan == null || rawPlan.isEmpty) {
      plan = legacyUnlocked ? PremiumPlan.plus : PremiumPlan.none;
    } else {
      plan = PremiumPlan.values.byName(rawPlan);
    }

    return PremiumStatus(
      plan: plan,
      showUpgradePrompts: prefs.getBool(_upgradePromptsKey) ?? true,
    );
  }

  Future<void> saveStatus(PremiumStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_premiumPlanKey, status.plan.name);
    await prefs.setBool(_legacyPremiumUnlockedKey, status.isUnlocked);
    await prefs.setBool(_upgradePromptsKey, status.showUpgradePrompts);
  }

  Future<void> setPlan(PremiumPlan plan) async {
    final current = await getStatus();
    await saveStatus(current.copyWith(plan: plan));
  }

  Future<void> setUnlocked(bool value) async {
    await setPlan(value ? PremiumPlan.plus : PremiumPlan.none);
  }

  Future<void> setUpgradePrompts(bool value) async {
    final current = await getStatus();
    await saveStatus(current.copyWith(showUpgradePrompts: value));
  }
}
