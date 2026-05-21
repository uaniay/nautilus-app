import 'package:flutter_test/flutter_test.dart';
import 'package:nautilus_app/main.dart';
import 'package:nautilus_app/services/notification_service.dart';

void main() {
  testWidgets('App renders connect screen', (WidgetTester tester) async {
    final notificationService = NotificationService();
    await tester.pumpWidget(NautilusApp(notificationService: notificationService));
    expect(find.text('Nautilus'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });
}
