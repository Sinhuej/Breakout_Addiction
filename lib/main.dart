import 'package:flutter/material.dart';

import 'app/breakout_app.dart';
import 'features/notifications/data/breakout_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BreakoutNotificationService.instance.initialize();
  runApp(const BreakoutApp());
}
