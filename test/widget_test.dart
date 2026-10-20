import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uninsta/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('UnInsta app loads and displays title', (WidgetTester tester) async {
    await tester.pumpWidget(const UnInstaApp());
    await tester.pumpAndSettle();

    // Verify app title
    expect(find.text('UnInsta'), findsOneWidget);
    // Verify import button
    expect(find.text('Select Instagram .zip File'), findsOneWidget);
    // Verify how to get export info
    expect(find.text('How to get your Instagram export:'), findsOneWidget);
  });
}
