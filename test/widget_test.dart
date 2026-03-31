import 'package:flutter_test/flutter_test.dart';
import 'package:breakout_addiction/app/breakout_app.dart';

void main() {
  testWidgets('BreakoutApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const BreakoutApp());
    expect(find.text('Breakout Addiction'), findsOneWidget);
  });
}
