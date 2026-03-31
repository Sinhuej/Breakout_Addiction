import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';

class LockGateScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<bool> Function(String passcode) onUnlockAttempt;
  final VoidCallback onUnlockSuccess;

  const LockGateScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onUnlockAttempt,
    required this.onUnlockSuccess,
  });

  @override
  State<LockGateScreen> createState() => _LockGateScreenState();
}

class _LockGateScreenState extends State<LockGateScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isBusy = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() {
      _isBusy = true;
      _errorText = null;
    });

    final ok = await widget.onUnlockAttempt(_controller.text.trim());

    if (!mounted) {
      return;
    }

    setState(() => _isBusy = false);

    if (ok) {
      widget.onUnlockSuccess();
      return;
    }

    setState(() => _errorText = 'That code does not match.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protected')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: InfoCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  Text(widget.subtitle, style: AppTypography.muted),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _controller,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Passcode',
                      border: const OutlineInputBorder(),
                      errorText: _errorText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: _isBusy ? 'Unlocking...' : 'Unlock',
                    icon: Icons.lock_open,
                    onPressed: _isBusy ? () {} : _unlock,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
