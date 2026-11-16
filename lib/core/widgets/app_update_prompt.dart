import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_update_service.dart';

/// One prompt per available version and app session, including before login.
class AppUpdatePrompt extends ConsumerStatefulWidget {
  const AppUpdatePrompt({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends ConsumerState<AppUpdatePrompt>
    with WidgetsBindingObserver {
  final _offeredVersions = <String>{};
  DateTime? _lastCheck;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (!mounted || _checking) return;
    final lastCheck = _lastCheck;
    if (lastCheck != null &&
        DateTime.now().difference(lastCheck) < const Duration(minutes: 15)) {
      return;
    }
    _checking = true;
    _lastCheck = DateTime.now();
    try {
      final service = ref.read(appUpdateServiceProvider);
      final update = await service.check();
      if (!mounted || update == null || !_offeredVersions.add(update.id)) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => _UpdateDialog(update: update, service: service),
      );
    } catch (_) {
      // Store/network failures must not prevent access to the application.
      debugPrint(
        'Vérification de mise à jour indisponible. Nouvel essai au retour dans l\'application.',
      );
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.update, required this.service});

  final AvailableAppUpdate update;
  final AppUpdateService service;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _opening = false;
  String? _error;

  Future<void> _open() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      await widget.service.openUpdate(widget.update);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _opening = false;
          _error = 'Impossible d\'ouvrir la mise à jour. Réessaie plus tard.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Mise à jour disponible'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.update.isWeb
              ? 'Une nouvelle version est disponible. Recharge la page pour en profiter. Les modifications non enregistrées seront perdues.'
              : 'Une nouvelle version de CHC MVP est disponible sur Google Play.',
        ),
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Semantics(liveRegion: true, child: Text(error)),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Plus tard'),
      ),
      FilledButton(
        onPressed: _opening ? null : _open,
        child: Text(widget.update.isWeb ? 'Recharger' : 'Mettre à jour'),
      ),
    ],
  );
}
