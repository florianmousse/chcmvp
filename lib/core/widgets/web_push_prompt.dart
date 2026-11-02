import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/web_push.dart';
import '../services/messaging_service.dart';
import '../providers/messaging_providers.dart';
import '../../features/auth/presentation/auth_providers.dart';

/// The global instance owns subscriptions; the profile instance is always visible.
class WebPushPrompt extends ConsumerStatefulWidget {
  const WebPushPrompt({super.key, this.child});
  final Widget? child;
  @override
  ConsumerState<WebPushPrompt> createState() => _WebPushPromptState();
}

class _WebPushPromptState extends ConsumerState<WebPushPrompt>
    with WidgetsBindingObserver {
  bool _supported = false, _busy = false, _hidden = WebPush.dismissed;
  String? _error, _target;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool get _global => widget.child != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WebPush.subscribedUid.addListener(_refresh);
    if (_global) _target = WebPush.takeTarget();
    _initialize();
  }

  void _refresh() {
    if (mounted) setState(() => _error = null);
  }

  Future<void> _initialize() async {
    final supported = await WebPush.supported();
    if (!mounted) return;
    setState(() => _supported = supported);
    if (_global && supported) {
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((message) {
          if (!mounted) return;
          final text =
              message.notification?.body ?? message.notification?.title;
          if (text == null ||
              ref.read(currentUserProfileProvider).value?.isActive != true) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(text),
              action: SnackBarAction(
                label: 'Ouvrir',
                onPressed: () => ref.read(notificationOpenerProvider)(
                  notificationTarget(message.data),
                ),
              ),
            ),
          );
        }),
      );
      _subscriptions.add(
        FirebaseMessaging.instance.onTokenRefresh.listen((_) => _sync()),
      );
    }
    _sync();
  }

  void _sync() {
    final profile = ref.read(currentUserProfileProvider).value;
    if (profile == null || !profile.isActive) return;
    if (_target != null && _global) {
      final target = _target;
      _target = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(notificationOpenerProvider)(target);
      });
    }
    if (_supported && WebPush.permission == 'granted') {
      WebPush.sync(profile.uid)
          .then((_) {
            _refresh();
          })
          .catchError((Object _) {
            if (mounted) {
              setState(
                () => _error =
                    'Connexion aux notifications impossible. Réessaie.',
              );
            }
          });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync();
      if (mounted) setState(() {});
    }
  }

  Future<void> _enable() async {
    // Keep this call before any await to preserve iOS user activation.
    final permission = WebPush.requestPermission();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (await permission == 'granted') {
        final uid = ref.read(currentUserProfileProvider).value?.uid;
        if (uid != null) {
          await WebPush.sync(uid);
        }
      }
    } catch (_) {
      _error = 'Activation impossible. Vérifie ta connexion puis réessaie.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProfileProvider, (previous, next) {
      if (previous?.value?.uid != next.value?.uid ||
          previous?.value?.isActive != next.value?.isActive) {
        _sync();
      }
    });
    final profile = ref.watch(currentUserProfileProvider).value;
    final installed = !WebPush.needsInstall;
    final granted =
        WebPush.permission == 'granted' &&
        WebPush.subscribedUid.value == profile?.uid &&
        WebPush.subscribedUid.value != null;
    final denied = WebPush.permission == 'denied';
    final visible =
        !_global ||
        (!_hidden &&
            !granted &&
            (!installed || (_supported && profile?.isActive == true)));
    final text = !installed
        ? 'Sur iPhone ou iPad, ouvre CHC MVP dans Safari, puis Partager → Sur l’écran d’accueil. Ouvre ensuite cette icône pour activer les notifications.'
        : granted
        ? 'Les notifications sont activées sur cet appareil.'
        : denied
        ? 'Les notifications sont bloquées. Autorise CHC MVP dans les réglages de notifications de ton appareil ou de ton navigateur.'
        : !_supported
        ? 'Ce navigateur ne permet pas les notifications web. Sur iPhone, utilise iOS 16.4 ou une version plus récente.'
        : !WebPush.configured
        ? 'Les notifications web seront bientôt disponibles.'
        : 'Reçois les ouvertures de vote, rappels et résultats du club.';
    final panel = Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications du club',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(_error ?? text),
              Wrap(
                spacing: 8,
                children: [
                  if (installed &&
                      _supported &&
                      WebPush.configured &&
                      !denied &&
                      !granted &&
                      profile?.isActive == true)
                    FilledButton(
                      onPressed: _busy ? null : _enable,
                      child: Text(
                        _busy ? 'Activation…' : 'Activer les notifications',
                      ),
                    ),
                  if (_global)
                    TextButton(
                      onPressed: () {
                        WebPush.dismiss();
                        setState(() => _hidden = true);
                      },
                      child: const Text('Plus tard'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!_global) return panel;
    return Column(
      children: [
        if (visible) panel,
        Expanded(child: widget.child!),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WebPush.subscribedUid.removeListener(_refresh);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
