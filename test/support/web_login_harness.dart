import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:chc_mvp/core/theme/app_theme.dart';
import 'package:chc_mvp/features/auth/presentation/web_login_form.dart';

void main() => runApp(const MaterialApp(home: Harness()));

class Harness extends StatefulWidget {
  const Harness({super.key});
  @override
  State<Harness> createState() => HarnessState();
}

class HarnessState extends State<Harness> {
  String result = 'Waiting';
  bool busy = false;
  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.light,
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WebLoginForm(
                busy: busy,
                onSubmit: (email, password) => setState(() {
                  result =
                      email == 'demo@example.test' &&
                          password == 'autofill-demo-value'
                      ? 'AUTOFILL_OK'
                      : 'AUTOFILL_ERROR';
                  web.document.body!.setAttribute('data-login-result', result);
                  busy = true;
                }),
                onForgot: (email) => setState(() {
                  result = 'FORGOT_OK';
                }),
              ),
              Text(result),
            ],
          ),
        ),
      ),
    ),
  );
}
