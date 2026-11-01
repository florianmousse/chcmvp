import 'dart:async';
import 'package:flutter/material.dart';
import 'ceremony_model.dart';

class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key, required this.ceremony});
  final Ceremony ceremony;
  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  int _index = -1;
  Timer? _timer;
  late final ranks =
      widget.ceremony.revealedTop.map((r) => r.rank).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
  void _next() {
    if (_index + 1 < ranks.length) setState(() => _index++);
    if (_index == ranks.length - 1) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final rank = _index >= 0 ? ranks[_index] : null;
    final rows = widget.ceremony.revealedTop
        .where((r) => r.rank == rank)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.ceremony.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              const Text('LA CÉRÉMONIE', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: Duration(milliseconds: reduced ? 0 : 700),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: Card(
                  key: ValueKey(rank),
                  color: rank == 1 ? const Color(0xffffe7a0) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Icon(
                          rank == 1 ? Icons.emoji_events : Icons.auto_awesome,
                          size: 72,
                          color: rank == 1
                              ? const Color(0xff7a5100)
                              : Theme.of(context).colorScheme.primary,
                        ),
                        Text(
                          rank == null
                              ? 'Prêts pour la révélation ?'
                              : rank == 1
                              ? '1er · ${rows.length > 1 ? 'Ex æquo' : 'Lauréat'}'
                              : '$rankᵉ place',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: rank == 1 ? Colors.black87 : null,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        for (final row in rows)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              children: [
                                Text(
                                  row.nominee.name,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: rank == 1
                                            ? Colors.black87
                                            : null,
                                      ),
                                ),
                                Text(
                                  '${row.nominee.label} · ${row.points} pts',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: rank == 1 ? Colors.black87 : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (ranks.isEmpty)
                const Text(
                  'Aucun vote reçu : aucun trophée attribué.',
                  textAlign: TextAlign.center,
                )
              else if (_index < ranks.length - 1) ...[
                FilledButton(
                  onPressed: _next,
                  child: Text(
                    _index < 0
                        ? 'Lancer la révélation'
                        : 'Révéler la place suivante',
                  ),
                ),
                if (!reduced)
                  TextButton(
                    onPressed: () => setState(() {
                      if (_timer != null) {
                        _timer!.cancel();
                        _timer = null;
                      } else {
                        _next();
                        if (_index < ranks.length - 1) {
                          _timer = Timer.periodic(
                            const Duration(seconds: 5),
                            (_) => _next(),
                          );
                        }
                      }
                    }),
                    child: Text(
                      _timer == null
                          ? 'Lecture automatique'
                          : 'Mettre en pause',
                    ),
                  ),
              ] else
                FilledButton(
                  onPressed: () => setState(() => _index = -1),
                  child: const Text('Rejouer la cérémonie'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour aux résultats'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
