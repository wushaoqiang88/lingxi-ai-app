import 'package:flutter_test/flutter_test.dart';

import 'package:ai_super_app/main.dart';

void main() {
  testWidgets('Lingxi home renders core modules', (WidgetTester tester) async {
    await tester.pumpWidget(const LingxiApp());

    expect(find.text('灵犀 AI'), findsOneWidget);
    expect(find.text('高频入口'), findsOneWidget);
    expect(find.text('灵伴'), findsWidgets);
    expect(find.text('妙笔'), findsWidgets);
  });
}
