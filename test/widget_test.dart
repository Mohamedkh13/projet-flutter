import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:projet/screens/login_screen.dart';

void main() {
  testWidgets('shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onGoogleSignIn: () async {})),
    );

    expect(find.text('Flutter Admin Portal'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
