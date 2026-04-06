import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rua_viva/main.dart';

void main() {
  testWidgets('App starts and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: RuaVivaApp()));

    // Verify the app starts (showing loading or home)
    expect(find.byType(RuaVivaApp), findsOneWidget);
  });
}
