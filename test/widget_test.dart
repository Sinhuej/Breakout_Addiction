import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakout_addiction/app/breakout_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final Map<String, String> secureStorage = <String, String>{};

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding_completed': true,
      'quote_mode': 'recovery',
      'quote_religion': 'Christian',
      'privacy_neutral_mode': false,
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall call) async {
      final args = call.arguments;
      final Map<dynamic, dynamic> map =
          args is Map ? args : <dynamic, dynamic>{};

      switch (call.method) {
        case 'read':
          final String key = map['key'] as String;
          return secureStorage[key];
        case 'write':
          final String key = map['key'] as String;
          final String value = map['value'] as String;
          secureStorage[key] = value;
          return null;
        case 'delete':
          final String key = map['key'] as String;
          secureStorage.remove(key);
          return null;
        case 'deleteAll':
          secureStorage.clear();
          return null;
        case 'containsKey':
          final String key = map['key'] as String;
          return secureStorage.containsKey(key);
        case 'readAll':
          return secureStorage;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
    secureStorage.clear();
  });

  testWidgets('BreakoutApp renders home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const BreakoutApp());
    await tester.pumpAndSettle();

    expect(find.text('Breakout Addiction'), findsOneWidget);
    expect(find.text('Break the cycle earlier.'), findsOneWidget);
    expect(find.text('Daily Focus'), findsOneWidget);
  });
}
