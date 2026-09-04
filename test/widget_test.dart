import 'package:attendancesystem/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App boots to the role selection screen when logged out',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AttendanceApp());

    // Let the splash screen initialize the session and navigate.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));

    // The role selection screen is shown when no session is stored.
    expect(find.text('Who is signing in?'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
  });
}