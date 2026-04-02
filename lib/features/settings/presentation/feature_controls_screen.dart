import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../data/feature_control_settings_repository.dart';
import '../domain/feature_control_settings.dart';

class FeatureControlsScreen extends StatefulWidget {
  const FeatureControlsScreen({super.key});

  @override
  State<FeatureControlsScreen> createState() => _FeatureControlsScreenState();
}

class _FeatureControlsScreenState extends State<FeatureControlsScreen> {
  final FeatureControlSettingsRepository _repository =
      FeatureControlSettingsRepository();

  FeatureControlSettings _settings = FeatureControlSettings.defaults();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.getSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(FeatureControlSettings updated) async {
    await _repository.saveSettings(updated);
    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feature Controls')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Feature Controls')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Choose your comfort level.', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'You do not need to use every feature. Keep the app as simple, private, and low-pressure as you want.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Core Controls', style: AppTypography.section),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.showStartupNotice,
                  onChanged: (value) => _save(
                    _settings.copyWith(showStartupNotice: value),
                  ),
                  title: const Text('Show startup notice'),
                  subtitle: const Text(
                    'Show the calm welcome and privacy reminder when the app opens.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.faithLayerEnabled,
                  onChanged: (value) => _save(
                    _settings.copyWith(faithLayerEnabled: value),
                  ),
                  title: const Text('Faith layer'),
                  subtitle: const Text(
                    'Enable or hide faith-sensitive guidance and preferences.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Controls', style: AppTypography.section),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.aiGuidanceEnabled,
                  onChanged: (value) => _save(
                    _settings.copyWith(aiGuidanceEnabled: value),
                  ),
                  title: const Text('AI quotes / guidance'),
                  subtitle: const Text(
                    'Reserved for optional AI-generated guidance later.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.aiChatEnabled,
                  onChanged: (value) => _save(
                    _settings.copyWith(aiChatEnabled: value),
                  ),
                  title: const Text('AI chat'),
                  subtitle: const Text(
                    'Turn AI conversation features on or off.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _settings.remoteAiFeaturesEnabled,
                  onChanged: (value) => _save(
                    _settings.copyWith(remoteAiFeaturesEnabled: value),
                  ),
                  title: const Text('Remote AI features'),
                  subtitle: const Text(
                    'Arms remote AI paths only when premium and preflight allow it.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
