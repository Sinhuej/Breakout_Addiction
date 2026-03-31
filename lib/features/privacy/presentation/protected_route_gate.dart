import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../data/lock_settings_repository.dart';
import '../domain/lock_scope.dart';
import '../domain/lock_settings.dart';
import 'lock_gate_screen.dart';

class ProtectedRouteGate extends StatefulWidget {
  final LockScope scope;
  final Widget child;
  final bool isRescueRoute;

  const ProtectedRouteGate({
    super.key,
    required this.scope,
    required this.child,
    this.isRescueRoute = false,
  });

  @override
  State<ProtectedRouteGate> createState() => _ProtectedRouteGateState();
}

class _ProtectedRouteGateState extends State<ProtectedRouteGate> {
  final LockSettingsRepository _repository = LockSettingsRepository();

  LockSettings? _settings;
  bool _loading = true;
  bool _sessionUnlocked = false;

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

  @override
  Widget build(BuildContext context) {
    if (_loading || _settings == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final settings = _settings!;

    final rescueBypass = widget.isRescueRoute && settings.allowRescueWithoutUnlock;
    final shouldLock = settings.shouldLock(widget.scope);

    if (_sessionUnlocked || rescueBypass || !shouldLock || !settings.hasPasscode) {
      return widget.child;
    }

    return LockGateScreen(
      title: 'Protected Content',
      subtitle: 'Unlock to continue.',
      onUnlockAttempt: _repository.verifyPasscode,
      onUnlockSuccess: () {
        setState(() => _sessionUnlocked = true);
      },
    );
  }
}
