import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../ai_chat/data/ai_backend_config_repository.dart';
import '../../ai_chat/data/ai_backend_preflight_service.dart';
import '../../ai_chat/data/ai_chat_settings_repository.dart';
import '../../ai_chat/data/ai_runtime_gate_repository.dart';
import '../../ai_chat/domain/ai_backend_config.dart';
import '../../ai_chat/domain/ai_preflight_status.dart';
import '../../ai_chat/domain/chat_provider_mode.dart';
import '../data/premium_access_repository.dart';
import '../domain/premium_status.dart';
import 'widgets/premium_badge.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PremiumAccessRepository _repository = PremiumAccessRepository();
  final AiChatSettingsRepository _chatSettingsRepository =
      AiChatSettingsRepository();
  final AiBackendConfigRepository _backendRepository =
      AiBackendConfigRepository();
  final AiRuntimeGateRepository _runtimeGateRepository =
      AiRuntimeGateRepository();
  final AiBackendPreflightService _preflightService =
      AiBackendPreflightService();

  PremiumStatus _status = PremiumStatus.defaults();
  ChatProviderMode _providerMode = ChatProviderMode.mock;
  AiBackendConfig _backendConfig = AiBackendConfig.defaults();
  AiPreflightStatus _preflight = AiPreflightStatus.initial();
  bool _remotePathEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _repository.getStatus();
    final chatSettings = await _chatSettingsRepository.getSettings();
    final backendConfig = await _backendRepository.getConfig();
    final remotePathEnabled = await _runtimeGateRepository.getRemotePathEnabled();
    final preflight = await _preflightService.run();

    if (!mounted) {
      return;
    }

    setState(() {
      _status = status;
      _providerMode = chatSettings.providerMode;
      _backendConfig = backendConfig;
      _remotePathEnabled = remotePathEnabled;
      _preflight = preflight;
      _loading = false;
    });
  }

  Future<void> _toggleDemoUnlock(bool value) async {
    await _repository.setUnlocked(value);
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value
            ? 'Premium demo unlocked locally.'
            : 'Premium demo returned to locked state.'),
      ),
    );
  }

  Future<void> _togglePrompts(bool value) async {
    await _repository.setUpgradePrompts(value);
    await _load();
  }

  Future<void> _setProviderMode(ChatProviderMode mode) async {
    await _chatSettingsRepository.setProviderMode(mode);
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('AI provider mode set to ${mode.label}.')),
    );
  }

  Future<void> _setRemotePathEnabled(bool value) async {
    await _runtimeGateRepository.setRemotePathEnabled(value);
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Remote backend path enabled, but still stubbed.'
              : 'Remote backend path disabled.',
        ),
      ),
    );
  }

  Future<void> _showBackendSheet() async {
    final modelController = TextEditingController(text: _backendConfig.modelName);
    final baseUrlController = TextEditingController(text: _backendConfig.apiBaseUrl);
    final apiKeyController = TextEditingController();

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
              Text('Backend Config', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'This prepares the future paid backend path. Risky features stay disabled on purpose.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model Name',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'API Base URL',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: apiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key (optional for later)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Forced-off features', style: AppTypography.section),
                    SizedBox(height: AppSpacing.sm),
                    Text('Grounding: off', style: AppTypography.body),
                    SizedBox(height: 4),
                    Text('Maps grounding: off', style: AppTypography.body),
                    SizedBox(height: 4),
                    Text('Session memory: off', style: AppTypography.body),
                    SizedBox(height: 4),
                    Text('File uploads: off', style: AppTypography.body),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Save Backend Config',
                icon: Icons.save_outlined,
                onPressed: () async {
                  final updated = _backendConfig.copyWith(
                    modelName: modelController.text.trim().isEmpty
                        ? _backendConfig.modelName
                        : modelController.text.trim(),
                    apiBaseUrl: baseUrlController.text.trim().isEmpty
                        ? _backendConfig.apiBaseUrl
                        : baseUrlController.text.trim(),
                    allowGrounding: false,
                    allowMapsGrounding: false,
                    allowSessionMemory: false,
                    allowFileUploads: false,
                  );

                  await _backendRepository.saveConfig(updated);

                  final apiKey = apiKeyController.text.trim();
                  if (apiKey.isNotEmpty) {
                    await _backendRepository.saveApiKey(apiKey);
                  }

                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                  }
                  await _load();

                  if (!mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backend config saved.')),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _backendRepository.clearApiKey();
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                    await _load();
                    if (!mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved API key removed.')),
                    );
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Saved API Key'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _featureCard({
    required String title,
    required String subtitle,
  }) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTypography.section),
              const SizedBox(width: 8),
              const PremiumBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: AppTypography.muted),
        ],
      ),
    );
  }

  Widget _preflightCard() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paid Path Preflight', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text('Provider: ${_preflight.providerModeLabel}', style: AppTypography.body),
          const SizedBox(height: 4),
          Text(
            _preflight.remotePathEnabled
                ? 'Remote path: enabled'
                : 'Remote path: disabled',
            style: AppTypography.body,
          ),
          const SizedBox(height: 4),
          Text(
            _preflight.apiKeyPresent ? 'API key: present' : 'API key: missing',
            style: AppTypography.body,
          ),
          const SizedBox(height: 4),
          Text(
            _preflight.riskyFeaturesForcedOff
                ? 'Risky features: forced off'
                : 'Risky features: unsafe',
            style: AppTypography.body,
          ),
          const SizedBox(height: 8),
          Text(_preflight.summaryLine, style: AppTypography.muted),
          if (_preflight.blockerLines.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final line in _preflight.blockerLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $line', style: AppTypography.body),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Premium')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Breakout Plus', style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Core recovery help stays free. Premium is for deeper guidance, richer learning, and future advanced tools.',
            style: AppTypography.muted,
          ),
          const SizedBox(height: AppSpacing.lg),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Access', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _status.isUnlocked ? 'Premium unlocked' : 'Premium locked',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _status.isUnlocked,
                  onChanged: _toggleDemoUnlock,
                  title: const Text('Local Demo Unlock'),
                  subtitle: const Text(
                    'Safe dev toggle for local testing until real billing is wired later.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _status.showUpgradePrompts,
                  onChanged: _togglePrompts,
                  title: const Text('Show Upgrade Prompts'),
                  subtitle: const Text(
                    'Controls whether soft premium prompts appear in the app.',
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
                Text('AI Chat Provider Mode', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Choose the prototype provider path. Keep using sanitized dummy prompts only until the real privacy-safe backend is ready.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<ChatProviderMode>(
                  initialValue: _providerMode,
                  decoration: const InputDecoration(
                    labelText: 'Provider Mode',
                  ),
                  items: ChatProviderMode.values
                      .map(
                        (mode) => DropdownMenuItem<ChatProviderMode>(
                          value: mode,
                          child: Text(mode.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _setProviderMode(value);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _providerMode.description,
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
                Text('Remote Path Kill Switch', style: AppTypography.section),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _remotePathEnabled,
                  onChanged: _setRemotePathEnabled,
                  title: const Text('Enable Remote Backend Path'),
                  subtitle: const Text(
                    'This arms the paid backend path only after all preflight checks pass. It still uses a stub transport today.',
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
                Text('Paid Backend Readiness', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text('Model: ${_backendConfig.modelName}', style: AppTypography.body),
                const SizedBox(height: 4),
                Text('Base URL: ${_backendConfig.apiBaseUrl}', style: AppTypography.body),
                const SizedBox(height: 4),
                Text(
                  _backendConfig.hasApiKey ? 'API key saved securely' : 'No API key saved',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Grounding, maps grounding, session memory, and file uploads are intentionally forced off.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Backend Config',
                  icon: Icons.admin_panel_settings_outlined,
                  onPressed: _showBackendSheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _preflightCard(),
          const SizedBox(height: AppSpacing.md),
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prototype AI Guardrails', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'The current prototype blocks minor sexual content and imminent self-harm or violence language, and scrubs obvious identifying details before prototype processing.',
                  style: AppTypography.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _featureCard(
            title: 'Educate Me Plus',
            subtitle:
                'Deeper pattern breakdowns, topic tracks, and richer learning modules.',
          ),
          const SizedBox(height: AppSpacing.md),
          _featureCard(
            title: 'Advanced Insights',
            subtitle:
                'Longer pattern history, stronger summaries, and more detailed behavior trends.',
          ),
          const SizedBox(height: AppSpacing.md),
          _featureCard(
            title: 'Future Coaching Layer',
            subtitle:
                'Reserved space for later premium guidance and expanded support tools.',
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _status.isUnlocked ? 'Premium Active' : 'Upgrade Hooks Ready',
            icon: Icons.workspace_premium_outlined,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
