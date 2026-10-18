import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Persistent, visible DOM inputs allow password managers to inspect the form
/// even before focus. Values are read on submit, including autofill without events.
class WebLoginForm extends StatefulWidget {
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
  State<WebLoginForm> createState() => _WebLoginFormState();
}

class _WebLoginFormState extends State<WebLoginForm> {
  web.HTMLFormElement? _form;
  late web.HTMLInputElement _email;
  late web.HTMLInputElement _password;
  late web.HTMLButtonElement _submit;
  late web.HTMLButtonElement _forgot;
  late web.HTMLButtonElement _toggle;

  void _create(Object element) {
    final host = element as web.HTMLElement;
    final form = web.HTMLFormElement()..id = 'chc-login-form';
    _form = form;
    form.setAttribute('autocomplete', 'on');
    form.setAttribute('aria-label', 'Connexion CHC MVP');
    form.style.cssText =
        'font:16px Arial,sans-serif;display:flex;flex-direction:column;gap:8px;margin:0;width:100%;';
    _email = web.HTMLInputElement()
      ..id = 'chc-login-email'
      ..name = 'username'
      ..type = 'email'
      ..autocomplete = 'username'
      ..required = true;
    _email.setAttribute('inputmode', 'email');
    _email.setAttribute('autocapitalize', 'none');
    _email.spellcheck = false;
    _password = web.HTMLInputElement()
      ..id = 'chc-login-password'
      ..name = 'password'
      ..type = 'password'
      ..autocomplete = 'current-password'
      ..required = true;
    for (final entry in [(_email, 'E-mail'), (_password, 'Mot de passe')]) {
      final label = web.HTMLLabelElement()
        ..htmlFor = entry.$1.id
        ..textContent = entry.$2;
      label.style.cssText = 'font-size:14px;margin-top:4px;';
      entry.$1.style.cssText =
          'font:inherit;box-sizing:border-box;width:100%;height:48px;padding:10px 12px;border:1px solid;border-radius:6px;';
      form.appendChild(label);
      if (entry.$1 == _password) {
        final row = web.HTMLDivElement()..style.cssText = 'position:relative;';
        _password.style.paddingRight = '84px';
        _toggle = web.HTMLButtonElement()
          ..type = 'button'
          ..textContent = 'Afficher';
        _toggle.setAttribute('aria-label', 'Afficher le mot de passe');
        _toggle.style.cssText =
            'position:absolute;right:4px;top:4px;height:40px;border:0;background:transparent;cursor:pointer;';
        _toggle.addEventListener(
          'click',
          ((web.Event event) {
            final show = _password.type == 'password';
            _password.type = show ? 'text' : 'password';
            _toggle.textContent = show ? 'Masquer' : 'Afficher';
            _toggle.setAttribute(
              'aria-label',
              show ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
            );
          }).toJS,
        );
        row.appendChild(_password);
        row.appendChild(_toggle);
        form.appendChild(row);
      } else {
        form.appendChild(entry.$1);
      }
    }
    _forgot = web.HTMLButtonElement()
      ..type = 'button'
      ..textContent = 'Mot de passe oublié ?';
    _forgot.style.cssText =
        'align-self:flex-end;border:0;background:transparent;padding:8px 0;cursor:pointer;font:14px Arial,sans-serif;';
    _forgot.addEventListener(
      'click',
      ((web.Event event) {
        if (!widget.busy) widget.onForgot(_email.value.trim());
      }).toJS,
    );
    _submit = web.HTMLButtonElement()
      ..type = 'submit'
      ..textContent = 'Se connecter';
    _submit.style.cssText =
        'height:44px;border:0;border-radius:24px;font:600 14px Arial,sans-serif;cursor:pointer;';
    form.appendChild(_forgot);
    form.appendChild(_submit);
    form.addEventListener(
      'submit',
      ((web.Event event) {
        event.preventDefault();
        if (!widget.busy && form.reportValidity()) {
          widget.onSubmit(_email.value.trim(), _password.value);
        }
      }).toJS,
    );
    host.appendChild(form);
    _update();
  }

  String _css(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2)}';

  void _update() {
    if (_form == null) return;
    final colors = Theme.of(context).colorScheme;
    _form!.style.color = _css(colors.onSurface);
    for (final input in [_email, _password]) {
      input.style.backgroundColor = _css(colors.surface);
      input.style.color = _css(colors.onSurface);
      input.style.borderColor = _css(colors.outline);
      input.readOnly = widget.busy;
    }
    _submit.disabled = _forgot.disabled = widget.busy;
    _submit.textContent = widget.busy ? 'Connexion…' : 'Se connecter';
    _submit.style.backgroundColor = _css(colors.primary);
    _submit.style.color = _css(colors.onPrimary);
    _forgot.style.color = _toggle.style.color = _css(colors.primary);
  }

  @override
  void didUpdateWidget(covariant WebLoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void dispose() {
    if (_form != null) {
      _password.value = '';
      _form!.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 268,
    child: HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: _create,
    ),
  );
}
