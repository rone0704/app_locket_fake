// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_locket_fake/forgot_password_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Forgot password screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );

    expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
    expect(find.text('GỬI LIÊN KẾT ĐẶT LẠI'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
