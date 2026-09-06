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

    // The login screen is shown when no session is stored.
    expect(find.text('NTC A-Track'), findsOneWidget);
    expect(find.text('SIGN IN TO CONTINUE'), findsOneWidget);
    expect(find.text('Username or Student ID'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}