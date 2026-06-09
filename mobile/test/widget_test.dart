import 'package:flutter_test/flutter_test.dart';
import 'package:website_mobile/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const WebsiteApp());
    expect(find.text('Ganesha Energi'), findsOneWidget);
  });
}
