import 'package:flutter/material.dart';

class WebLoginForm extends StatelessWidget {
  const WebLoginForm({
    super.key,
    required this.busy,
    required this.onSubmit,
    required this.onForgot,
  });
  final bool busy;
  final void Function(String email, String password) onSubmit;
  final ValueChanged<String> onForgot;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
