#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-26 paid config scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/ai_chat/domain \
  lib/features/ai_chat/data \
  tools

cat > lib/features/ai_chat/domain/chat_provider_mode.dart <<'EOD'
enum ChatProviderMode {
  mock,
  geminiPrototype,
  vertexPrivateReady,
}

extension ChatProviderModeX on ChatProviderMode {
  String get label {
    switch (this) {
      case ChatProviderMode.mock:
        return 'Mock';
      case ChatProviderMode.geminiPrototype:
        return 'Gemini Prototype';
      case ChatProviderMode.vertexPrivateReady:
        return 'Vertex Private Ready';
    }
  }

  String get description {
    switch (this) {
      case ChatProviderMode.mock:
        return 'Local prototype replies only. No cloud calls.';
      case ChatProviderMode.geminiPrototype:
        return 'Cloud-ready prototype placeholder. Use sanitized dummy prompts only.';
      case ChatProviderMode.vertexPrivateReady:
        return 'Paid privacy-first configuration placeholder for later Vertex cutover. No live API call yet.';
    }
  }
}
EOD

cat > lib/features/ai_chat/domain/ai_backend_config.dart <<'EOD'
class AiBackendConfig {
  final String modelName;
  final String apiBaseUrl;
  final bool allowGrounding;
  final bool allowMapsGrounding;
  final bool allowSessionMemory;
  final bool allowFileUploads;
  final bool hasApiKey;

  const AiBackendConfig({
    required this.modelName,
    required this.apiBaseUrl,
    required this.allowGrounding,
    required this.allowMapsGrounding,
    required this.allowSessionMemory,
    required this.allowFileUploads,
    required this.hasApiKey,
  });

  factory AiBackendConfig.defaults() {
    return const AiBackendConfig(
      modelName: 'gemini-2.5-flash',
      apiBaseUrl: 'https://us-central1-aiplatform.googleapis.com',
      allowGrounding: false,
      allowMapsGrounding: false,
      allowSessionMemory: false,
      allowFileUploads: false,
      hasApiKey: false,
    );
  }

  AiBackendConfig copyWith({
    String? modelName,
    String? apiBaseUrl,
    bool? allowGrounding,
    bool? allowMapsGrounding,
    bool? allowSessionMemory,
    bool? allowFileUploads,
    bool? hasApiKey,
  }) {
    return AiBackendConfig(
      modelName: modelName ?? this.modelName,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      allowGrounding: allowGrounding ?? this.allowGrounding,
      allowMapsGrounding: allowMapsGrounding ?? this.allowMapsGrounding,
      allowSessionMemory: allowSessionMemory ?? this.allowSessionMemory,
      allowFileUploads: allowFileUploads ?? this.allowFileUploads,
      hasApiKey: hasApiKey ?? this.hasApiKey,
    );
  }
}
EOD

cat > lib/features/ai_chat/data/ai_backend_config_repository.dart <<'EOD'
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_backend_config.dart';

class AiBackendConfigRepository {
  static const String _modelNameKey = 'ai_backend_model_name';
  static const String _apiBaseUrlKey = 'ai_backend_api_base_url';
  static const String _allowGroundingKey = 'ai_backend_allow_grounding';
  static const String _allowMapsGroundingKey = 'ai_backend_allow_maps_grounding';
  static const String _allowSessionMemoryKey = 'ai_backend_allow_session_memory';
  static const String _allowFileUploadsKey = 'ai_backend_allow_file_uploads';
  static const String _apiKeyStorageKey = 'ai_backend_api_key';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<AiBackendConfig> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = await _secureStorage.read(key: _apiKeyStorageKey);

    return AiBackendConfig(
      modelName: prefs.getString(_modelNameKey) ?? 'gemini-2.5-flash',
      apiBaseUrl: prefs.getString(_apiBaseUrlKey) ??
          'https://us-central1-aiplatform.googleapis.com',
      allowGrounding: prefs.getBool(_allowGroundingKey) ?? false,
      allowMapsGrounding: prefs.getBool(_allowMapsGroundingKey) ?? false,
      allowSessionMemory: prefs.getBool(_allowSessionMemoryKey) ?? false,
      allowFileUploads: prefs.getBool(_allowFileUploadsKey) ?? false,
      hasApiKey: savedKey != null && savedKey.isNotEmpty,
    );
  }

  Future<void> saveConfig(AiBackendConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelNameKey, config.modelName);
    await prefs.setString(_apiBaseUrlKey, config.apiBaseUrl);
    await prefs.setBool(_allowGroundingKey, config.allowGrounding);
    await prefs.setBool(_allowMapsGroundingKey, config.allowMapsGrounding);
    await prefs.setBool(_allowSessionMemoryKey, config.allowSessionMemory);
    await prefs.setBool(_allowFileUploadsKey, config.allowFileUploads);
  }

  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  Future<void> clearApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }
}
EOD

cat > lib/features/ai_chat/data/vertex_private_ready_provider.dart <<'EOD'
import '../domain/chat_message.dart';
import '../domain/chat_provider.dart';

class VertexPrivateReadyProvider implements ChatProvider {
  @override
  Future<ChatMessage> generateReply({
    required List<ChatMessage> messages,
    required String userInput,
  }) async {
    return ChatMessage(
      role: ChatRole.assistant,
      text:
          'Vertex Private Ready mode is configured as a future paid backend path, but no live request is being made yet. Keep using sanitized dummy prompts until the real cutover is complete.',
      timestamp: DateTime.now(),
    );
  }
}
EOD
python3 - <<'EOD'
from pathlib import Path

factory_path = Path('lib/features/ai_chat/data/chat_provider_factory.dart')
factory_text = factory_path.read_text(encoding='utf-8')

if "import 'vertex_private_ready_provider.dart';" not in factory_text:
    factory_text = factory_text.replace(
        "import 'mock_recovery_coach_provider.dart';\n",
        "import 'mock_recovery_coach_provider.dart';\nimport 'vertex_private_ready_provider.dart';\n",
    )

factory_text = factory_text.replace(
"""class ChatProviderFactory {
  static ChatProvider create(ChatProviderMode mode) {
    switch (mode) {
      case ChatProviderMode.mock:
        return MockRecoveryCoachProvider();
      case ChatProviderMode.geminiPrototype:
        return GeminiPrototypeProvider();
    }
  }
}
""",
"""class ChatProviderFactory {
  static ChatProvider create(ChatProviderMode mode) {
    switch (mode) {
      case ChatProviderMode.mock:
        return MockRecoveryCoachProvider();
      case ChatProviderMode.geminiPrototype:
        return GeminiPrototypeProvider();
      case ChatProviderMode.vertexPrivateReady:
        return VertexPrivateReadyProvider();
    }
  }
}
""")

factory_path.write_text(factory_text, encoding='utf-8')
print('Patched chat_provider_factory.dart')
EOD

cat > lib/features/premium/presentation/premium_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../ai_chat/data/ai_backend_config_repository.dart';
import '../../ai_chat/data/ai_chat_settings_repository.dart';
import '../../ai_chat/domain/ai_backend_config.dart';
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

  PremiumStatus _status = PremiumStatus.defaults();
  ChatProviderMode _providerMode = ChatProviderMode.mock;
  AiBackendConfig _backendConfig = AiBackendConfig.defaults();
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

    if (!mounted) {
      return;
    }

    setState(() {
      _status = status;
      _providerMode = chatSettings.providerMode;
      _backendConfig = backendConfig;
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
EOD
cat > tools/verify_ba26.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/ai_chat/domain/chat_provider_mode.dart',
    'lib/features/ai_chat/domain/ai_backend_config.dart',
    'lib/features/ai_chat/data/ai_backend_config_repository.dart',
    'lib/features/ai_chat/data/vertex_private_ready_provider.dart',
    'lib/features/ai_chat/data/chat_provider_factory.dart',
    'lib/features/premium/presentation/premium_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/ai_chat/domain/chat_provider_mode.dart': 'vertexPrivateReady',
    'lib/features/ai_chat/domain/ai_backend_config.dart': 'class AiBackendConfig',
    'lib/features/ai_chat/data/ai_backend_config_repository.dart': 'class AiBackendConfigRepository',
    'lib/features/ai_chat/data/vertex_private_ready_provider.dart': 'Vertex Private Ready mode is configured',
    'lib/features/ai_chat/data/chat_provider_factory.dart': 'case ChatProviderMode.vertexPrivateReady:',
    'lib/features/premium/presentation/premium_screen.dart': 'Paid Backend Readiness',
}

def main() -> int:
    root = Path.cwd()

    missing = [path for path in REQUIRED if not (root / path).exists()]
    if missing:
      print('Missing files:')
      for item in missing:
        print(f' - {item}')
      return 1

    bad = []
    for path, needle in REQUIRED_TEXT.items():
      text = (root / path).read_text(encoding='utf-8')
      if needle not in text:
        bad.append((path, needle))

    if bad:
      print('Content checks failed:')
      for path, needle in bad:
        print(f' - {path} missing: {needle}')
      return 1

    print('Breakout Addiction BA-26 paid config verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-26 paid config scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba26.py
