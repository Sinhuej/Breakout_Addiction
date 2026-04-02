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
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
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
                        content: Text('Enter both a name and phone number.'),
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
                      content: Text('Saved trusted contact: ${contact.name}.'),
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
                Text('Feature Choices', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'You can keep things simple and local, or turn on optional features later. Nothing is forced.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Feature Controls',
                  icon: Icons.tune_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.featureControls,
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
                Text('Premium Options', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Breakout Plus gives curated local guidance and faith-sensitive packs without AI chat. Breakout Plus AI adds optional AI features later.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Premium',
                  icon: Icons.workspace_premium_outlined,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.premium,
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
                Text('Daily Encouragement', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Choose the tone and faith layer you want on the Home screen.',
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
    );
  }
}
