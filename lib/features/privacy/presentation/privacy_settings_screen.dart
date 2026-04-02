import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/lock_settings_repository.dart';
import '../domain/lock_scope.dart';
import '../domain/lock_settings.dart';
import 'widgets/neutral_mode_preview_card.dart';
import 'widgets/privacy_status_card.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final LockSettingsRepository _repository = LockSettingsRepository();

  LockSettings _settings = LockSettings.disabled();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _repository.getSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = loaded;
      _loading = false;
    });
  }

  Future<void> _saveSettings(LockSettings updated) async {
    await _repository.saveSettings(updated);
    if (!mounted) {
      return;
    }
    setState(() => _settings = updated);
  }

  Set<LockScope> _toggleScope(
    Set<LockScope> scopes,
    LockScope scope,
    bool enabled,
  ) {
    final next = <LockScope>{...scopes};
    if (enabled) {
      next.add(scope);
    } else {
      next.remove(scope);
    }
    return next;
  }

  Future<void> _showPasscodeSheet() async {
    final controller = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set Passcode', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Choose a simple 4-digit or longer passcode.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Passcode',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Save Passcode',
                icon: Icons.lock_outline,
                onPressed: () async {
                  final value = controller.text.trim();
                  if (value.length < 4) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text('Use at least 4 digits or characters.'),
                      ),
                    );
                    return;
                  }

                  await _repository.savePasscode(value);
                  if (!mounted) {
                    return;
                  }

                  await _saveSettings(_settings.copyWith(hasPasscode: true));
                  if (!mounted) {
                    return;
                  }

                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passcode saved.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removePasscode() async {
    await _repository.clearPasscode();
    final cleared = _settings.copyWith(
      hasPasscode: false,
      isEnabled: false,
      enabledScopes: <LockScope>{},
    );
    await _saveSettings(cleared);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passcode removed and locks disabled.')),
    );
  }

  Future<void> _resetDefaults() async {
    await _repository.resetToSafeDefaults();
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings reset to safe defaults.')),
    );
  }

  Widget _buildScopeTile({
    required String title,
    required String subtitle,
    required LockScope scope,
  }) {
    final enabled = _settings.enabledScopes.contains(scope);

    return SwitchListTile(
      value: enabled,
      onChanged: !_settings.hasPasscode
          ? null
          : (value) => _saveSettings(
                _settings.copyWith(
                  enabledScopes: _toggleScope(
                    _settings.enabledScopes,
                    scope,
                    value,
                  ),
                ),
              ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Privacy Lock Mode')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Lock Mode')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const PrivacyStatusCard(),
          const SizedBox(height: AppSpacing.md),
          NeutralModePreviewCard(neutralMode: _settings.neutralPrivacyMode),
          const SizedBox(height: AppSpacing.md),
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Layered Privacy', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Choose whether to lock the whole app or only the private areas.',
                  style: AppTypography.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Passcode', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _settings.hasPasscode
                      ? 'A passcode is currently set.'
                      : 'No passcode set yet.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: _settings.hasPasscode ? 'Update Passcode' : 'Set Passcode',
                  icon: Icons.password_outlined,
                  onPressed: _showPasscodeSheet,
                ),
                if (_settings.hasPasscode) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _removePasscode,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove Passcode'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lock Master Switch', style: AppTypography.section),
                SwitchListTile(
                  value: _settings.isEnabled,
                  onChanged: !_settings.hasPasscode
                      ? null
                      : (value) => _saveSettings(
                            _settings.copyWith(isEnabled: value),
                          ),
                  title: const Text('Enable Privacy Lock'),
                  subtitle: Text(
                    _settings.hasPasscode
                        ? 'Turn lock protection on or off.'
                        : 'Set a passcode first to enable lock protection.',
                  ),
                ),
                SwitchListTile(
                  value: _settings.allowRescueWithoutUnlock,
                  onChanged: !_settings.hasPasscode
                      ? null
                      : (value) => _saveSettings(
                            _settings.copyWith(allowRescueWithoutUnlock: value),
                          ),
                  title: const Text('Allow Rescue Without Unlock'),
                  subtitle: const Text(
                    'Keep the Rescue area available even when private areas are locked.',
                  ),
                ),
                SwitchListTile(
                  value: _settings.neutralPrivacyMode,
                  onChanged: (value) => _saveSettings(
                    _settings.copyWith(neutralPrivacyMode: value),
                  ),
                  title: const Text('Use Neutral Labels'),
                  subtitle: const Text(
                    'Use lower-key wording across the app and widget labels.',
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
                Text('Protected Areas', style: AppTypography.section),
                _buildScopeTile(
                  title: 'Lock Entire App',
                  subtitle: 'Require unlock across the whole app.',
                  scope: LockScope.app,
                ),
                _buildScopeTile(
                  title: 'Lock Private Logs',
                  subtitle: 'Protect stage logs and recovery logs.',
                  scope: LockScope.logs,
                ),
                _buildScopeTile(
                  title: 'Lock Cycle / History',
                  subtitle: 'Protect the cycle area.',
                  scope: LockScope.cycle,
                ),
                _buildScopeTile(
                  title: 'Lock Insights',
                  subtitle: 'Protect pattern summaries and analysis.',
                  scope: LockScope.insights,
                ),
                _buildScopeTile(
                  title: 'Lock Support Tools',
                  subtitle: 'Protect support, risk windows, and recovery plan.',
                  scope: LockScope.support,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reset', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Reset privacy settings to a safe default state while keeping your passcode intact.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetDefaults,
                    icon: const Icon(Icons.refresh_outlined),
                    label: const Text('Reset Privacy Defaults'),
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
