import 'package:shared_preferences/shared_preferences.dart';

import '../domain/premium_status.dart';

class PremiumAccessRepository {
  static const String _premiumUnlockedKey = 'premium_unlocked';
  static const String _upgradePromptsKey = 'premium_upgrade_prompts';

  Future<PremiumStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return PremiumStatus(
      isUnlocked: prefs.getBool(_premiumUnlockedKey) ?? false,
      showUpgradePrompts: prefs.getBool(_upgradePromptsKey) ?? true,
    );
  }

  Future<void> saveStatus(PremiumStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumUnlockedKey, status.isUnlocked);
    await prefs.setBool(_upgradePromptsKey, status.showUpgradePrompts);
  }

  Future<void> setUnlocked(bool value) async {
    final current = await getStatus();
    await saveStatus(current.copyWith(isUnlocked: value));
  }

  Future<void> setUpgradePrompts(bool value) async {
    final current = await getStatus();
    await saveStatus(current.copyWith(showUpgradePrompts: value));
  }
}
