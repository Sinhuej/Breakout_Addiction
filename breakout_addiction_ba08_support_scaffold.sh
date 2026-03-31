#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-08 support scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/support/domain \
  lib/features/support/data \
  tools

cat > pubspec.yaml <<'EOD'
name: breakout_addiction
description: Android-first recovery app for compulsive pornography use.
publish_to: "none"

version: 0.1.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.2.2
  url_launcher: ^6.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
EOD

cat > lib/features/support/domain/support_contact.dart <<'EOD'
class SupportContact {
  final String name;
  final String phone;

  const SupportContact({
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }

  factory SupportContact.fromMap(Map<String, dynamic> map) {
    return SupportContact(
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
    );
  }

  bool get isValid => name.trim().isNotEmpty && phone.trim().isNotEmpty;
}
EOD

cat > lib/features/support/data/support_contact_repository.dart <<'EOD'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/support_contact.dart';

class SupportContactRepository {
  static const String _storageKey = 'trusted_support_contact';

  Future<SupportContact?> getContact() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final contact = SupportContact.fromMap(decoded);
    return contact.isValid ? contact : null;
  }

  Future<void> saveContact(SupportContact contact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(contact.toMap()));
  }

  Future<void> clearContact() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
EOD
cat > lib/features/support/presentation/support_screen.dart <<'EOD'
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../quotes/data/quote_preferences_repository.dart';
import '../../quotes/domain/daily_quote.dart';
import '../data/support_contact_repository.dart';
import '../domain/support_contact.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final QuotePreferencesRepository _quotePreferences =
      QuotePreferencesRepository();
  final SupportContactRepository _contactRepository =
      SupportContactRepository();

  QuoteMode _mode = QuoteMode.recovery;
  String _religion = 'Christian';
  bool _loading = true;
  SupportContact? _trustedContact;

  static const List<String> _religions = <String>[
    'Christian',
    'General Faith',
    'Secular',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await _quotePreferences.getMode();
    final religion = await _quotePreferences.getReligionTag();
    final contact = await _contactRepository.getContact();

    if (!mounted) {
      return;
    }

    setState(() {
      _mode = mode;
      _religion = religion;
      _trustedContact = contact;
      _loading = false;
    });
  }

  Future<void> _saveMode(QuoteMode mode) async {
    await _quotePreferences.saveMode(mode);
    if (!mounted) {
      return;
    }
    setState(() => _mode = mode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${mode.name} quote mode.')),
    );
  }

  Future<void> _saveReligion(String value) async {
    await _quotePreferences.saveReligionTag(value);
    if (!mounted) {
      return;
    }
    setState(() => _religion = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved faith preference: $value.')),
    );
  }

  Future<void> _launchUri(Uri uri, String failureMessage) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage)),
      );
    }
  }

  Future<void> _call988() async {
    await _launchUri(
      Uri(scheme: 'tel', path: '988'),
      'Could not open the phone app for 988.',
    );
  }

  Future<void> _text988() async {
    await _launchUri(
      Uri(scheme: 'sms', path: '988'),
      'Could not open the messaging app for 988.',
    );
  }

  Future<void> _callTrustedContact() async {
    final contact = _trustedContact;
    if (contact == null) return;
    await _launchUri(
      Uri(scheme: 'tel', path: contact.phone),
      'Could not open the phone app for ${contact.name}.',
    );
  }

  Future<void> _textTrustedContact() async {
    final contact = _trustedContact;
    if (contact == null) return;
    await _launchUri(
      Uri(
        scheme: 'sms',
        path: contact.phone,
        queryParameters: <String, String>{
          'body': 'I need support right now. Please check on me.',
        },
      ),
      'Could not open messaging for ${contact.name}.',
    );
  }

  Future<void> _showTrustedContactSheet() async {
    final nameController =
        TextEditingController(text: _trustedContact?.name ?? '');
    final phoneController =
        TextEditingController(text: _trustedContact?.phone ?? '');

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
              Text('Trusted Contact', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Add one person you can reach quickly during a hard moment.',
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Save Contact',
                icon: Icons.person_add_alt_1_outlined,
                onPressed: () async {
                  final contact = SupportContact(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );

                  if (!contact.isValid) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter both a name and phone number.',
                        ),
                      ),
                    );
                    return;
                  }

                  await _contactRepository.saveContact(contact);
                  if (!mounted) {
                    return;
                  }

                  setState(() => _trustedContact = contact);
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Saved trusted contact: ${contact.name}.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _clearTrustedContact() async {
    await _contactRepository.clearContact();
    if (!mounted) {
      return;
    }
    setState(() => _trustedContact = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trusted contact removed.')),
    );
  }

  Widget _modeButton({
    required String label,
    required QuoteMode mode,
  }) {
    final selected = _mode == mode;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _saveMode(mode),
        child: Text(selected ? '$label ✓' : label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Support')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency Help', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Fast access to crisis support and trusted people.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Call 988',
                  icon: Icons.call_outlined,
                  onPressed: _call988,
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _text988,
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Text 988'),
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
                Text('Trusted Contact', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _trustedContact == null
                      ? 'No trusted contact saved yet.'
                      : 'Saved contact: ${_trustedContact!.name} • ${_trustedContact!.phone}',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: _trustedContact == null
                      ? 'Add Trusted Contact'
                      : 'Update Trusted Contact',
                  icon: Icons.person_outline,
                  onPressed: _showTrustedContactSheet,
                ),
                if (_trustedContact != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _callTrustedContact,
                      icon: const Icon(Icons.call_outlined),
                      label: Text('Call ${_trustedContact!.name}'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _textTrustedContact,
                      icon: const Icon(Icons.sms_outlined),
                      label: Text('Text ${_trustedContact!.name}'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearTrustedContact,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove Trusted Contact'),
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
                Text('Daily Encouragement', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Choose the tone you want on the Home screen.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _modeButton(
                      label: 'Motivational',
                      mode: QuoteMode.motivational,
                    ),
                    const SizedBox(width: 8),
                    _modeButton(
                      label: 'Recovery',
                      mode: QuoteMode.recovery,
                    ),
                    const SizedBox(width: 8),
                    _modeButton(
                      label: 'Faith',
                      mode: QuoteMode.faith,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _religion,
                  decoration: const InputDecoration(
                    labelText: 'Faith / Religion Preference',
                    border: OutlineInputBorder(),
                  ),
                  items: _religions
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _saveReligion(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy & Lock Mode', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Control who can open the app or view private areas like logs and cycle history.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Privacy Settings',
                  icon: Icons.lock_outline,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.privacySettings,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, RouteNames.insights);
              break;
            case 4:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on_outlined),
            label: 'Rescue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent_outlined),
            label: 'Support',
          ),
        ],
      ),
    );
  }
}
EOD
cat > tools/verify_ba08.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'pubspec.yaml',
    'lib/features/support/domain/support_contact.dart',
    'lib/features/support/data/support_contact_repository.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'pubspec.yaml': 'url_launcher:',
    'lib/features/support/domain/support_contact.dart': 'class SupportContact',
    'lib/features/support/data/support_contact_repository.dart': 'class SupportContactRepository',
    'lib/features/support/presentation/support_screen.dart': 'Call 988',
    'lib/features/support/presentation/support_screen.dart::__trusted': 'Trusted Contact',
    'lib/features/support/presentation/support_screen.dart::__text': 'Text 988',
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

    for key, needle in REQUIRED_TEXT.items():
        path = key.split('::__')[0]
        text = (root / path).read_text(encoding='utf-8')
        if needle not in text:
            bad.append((path, needle))

    if bad:
        print('Content checks failed:')
        for path, needle in bad:
            print(f' - {path} missing: {needle}')
        return 1

    print('Breakout Addiction BA-08 support scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-08 support scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba08.py
