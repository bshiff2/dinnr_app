import 'package:dinnr_app/login_page.dart';
import 'package:dinnr_app/main.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LoginPage shows form fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          auth: MockFirebaseAuth(),
        ),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('AuthGate shows HomePage when user is signed in', (tester) async {
    final mockUser = MockUser(email: 'chef@example.com');
    final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

    await tester.pumpWidget(MaterialApp(home: AuthGate(auth: mockAuth)));
    await tester.pump();

    expect(find.textContaining('chef@example.com'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
