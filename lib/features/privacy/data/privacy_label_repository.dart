import '../domain/lock_settings.dart';
import 'lock_settings_repository.dart';

class PrivacyLabelRepository {
  final LockSettingsRepository _lockRepository = LockSettingsRepository();

  Future<bool> isNeutralModeEnabled() async {
    final LockSettings settings = await _lockRepository.getSettings();
    return settings.neutralPrivacyMode;
  }
}
