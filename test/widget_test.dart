import 'package:flutter_test/flutter_test.dart';
import 'package:nautilus_app/main.dart';

void main() {
  testWidgets('App renders connect screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NautilusApp());
    expect(find.text('Nautilus'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });
}
