import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'ceremony_model.dart';
import 'ceremonies_providers.dart';
import 'ceremony_form.dart';
import 'reveal_screen.dart';
import 'youtube_video.dart';

class CeremoniesScreen extends ConsumerWidget {
  const CeremoniesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Cérémonies')),
    floatingActionButton: ref.watch(isAdminProvider)
        ? FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CeremonyForm()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Créer une cérémonie'),
          )
        : null,
    body: ResponsiveContent(
      maxWidth: 1000,
      child: ref
          .watch(ceremoniesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Cérémonies indisponibles : $e')),
            data: (events) {
              final visible = events
                  .where(
                    (e) => ref.watch(isAdminProvider) || e.status != 'draft',
                  )
                  .toList();
              if (visible.isEmpty) {
                return const Center(
                  child: Text('Les prochaines cérémonies apparaîtront ici.'),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  const Text(
                    'Les grands moments du club',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Vote pour tes favoris, découvre les lauréats et retrouve leurs trophées sur les profils.',
                  ),
                  const SizedBox(height: 16),
                  for (final event in visible)
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.emoji_events,
                          color: Color(0xffb68b22),
                          size: 36,
                        ),
                        title: Text(event.title),
                        subtitle: Text(
                          '${ceremonyCategories[event.category]} · Top ${event.topSize}\n${event.statusLabel} · ${event.voteCount}/${event.voterIds.length} votes',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CeremonyDetailScreen(id: event.id),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    ),
  );
}

class CeremonyDetailScreen extends ConsumerStatefulWidget {
  const CeremonyDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<CeremonyDetailScreen> createState() =>
      _CeremonyDetailScreenState();
}

class _CeremonyDetailScreenState extends ConsumerState<CeremonyDetailScreen> {
  final List<String?> _choices = [];
  int? _revision;
  bool _busy = false;
  Future<void> _action(
    String action,
    Map<String, dynamic> body,
    String confirm,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text(confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(serverClientProvider)
          .post('/ceremonies/${widget.id}/$action', body);
      if (action == 'delete' && mounted) {
        Navigator.pop(context);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'vote'
                  ? 'Vote enregistré, merci !'
                  : 'Cérémonie mise à jour.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cérémonie')),
    body: ResponsiveContent(
      maxWidth: 900,
      child: ref
          .watch(ceremoniesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (events) {
              final event = events.where((e) => e.id == widget.id).firstOrNull;
              if (event == null) {
                return const Center(child: Text('Cérémonie introuvable.'));
              }
              final admin = ref.watch(isAdminProvider);
              final uid = ref.watch(currentUserProfileProvider).value?.uid;
              final vote = ref.watch(myCeremonyVoteProvider(widget.id));
              final eligible = event.nominees
                  .where((n) => event.allowSelfVote || n.uid != uid)
                  .toList();
              if (_choices.length != event.topSize ||
                  _revision != event.revision) {
                _revision = event.revision;
                _choices.clear();
                _choices.addAll(List.filled(event.topSize, null));
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '${ceremonyCategories[event.category]} · ${event.statusLabel}',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${event.voteCount} / ${event.voterIds.length} personnes ont voté',
                  ),
                  Text(
                    'Top ${event.topSize} : ${List.generate(event.topSize, (i) => '${event.topSize - i}').join(' / ')} points. En cas d’égalité : nombre de premières places, puis suivantes. Égalité parfaite : rang et trophée partagés.',
                  ),
                  Text(
                    event.allowSelfVote
                        ? 'Auto-vote autorisé.'
                        : 'Tu ne peux pas voter pour tes propres nominations.',
                  ),
                  const SizedBox(height: 16),
                  if (admin)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (event.status != 'deleting')
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CeremonyForm(ceremony: event),
                                    ),
                                  ),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Modifier'),
                          ),
                        if (['closed', 'cancelled'].contains(event.status))
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _action(
                                    'reopen',
                                    {},
                                    'Rouvrir les votes ? Les bulletins valides sont conservés. Les résultats et trophées seront retirés jusqu’à la prochaine clôture. Les anciens bulletins contenant plusieurs fois le même joueur devront être refaits.',
                                  ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Rouvrir le vote'),
                          ),
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _action(
                                  'delete',
                                  {},
                                  'Supprimer définitivement cette cérémonie, tous ses bulletins, ses résultats et ses trophées ?',
                                ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Supprimer'),
                        ),
                        if (event.status == 'draft')
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _action(
                                    'open',
                                    {},
                                    'Ouvrir le vote avec cette liste de nommés et de votants ? Toute modification ultérieure remettra les votes à zéro.',
                                  ),
                            child: const Text('Ouvrir le vote'),
                          ),
                        if (event.status == 'open')
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _action(
                                    'close',
                                    {},
                                    'Clôturer le vote et publier les résultats ? Les lauréats recevront leur trophée.',
                                  ),
                            child: const Text('Clôturer et révéler'),
                          ),
                        if (['draft', 'open'].contains(event.status))
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _action(
                                    'cancel',
                                    {},
                                    'Annuler cette cérémonie sans attribuer de trophée ?',
                                  ),
                            child: const Text('Annuler la cérémonie'),
                          ),
                      ],
                    ),
                  if (_busy) const LinearProgressIndicator(),
                  if (event.status == 'open' && event.voterIds.contains(uid))
                    vote.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Ton vote est indisponible : $e'),
                      data: (saved) => saved != null
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                '✓ Ton vote est enregistré. Rendez-vous à la révélation !',
                              ),
                            )
                          : Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Ton classement',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Les joueurs déjà classés sont grisés. Efface une place avec la croix pour changer ton classement.',
                                    ),
                                    for (var i = 0; i < event.topSize; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: DropdownButtonFormField<String>(
                                          key: ValueKey(
                                            'choice-$i-${_choices[i]}',
                                          ),
                                          initialValue: _choices[i],
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            labelText:
                                                '${i + 1} · ${event.topSize - i} pts',
                                            border: const OutlineInputBorder(),
                                            suffixIcon: _choices[i] == null
                                                ? null
                                                : IconButton(
                                                    tooltip:
                                                        'Effacer la place ${i + 1}',
                                                    onPressed: _busy
                                                        ? null
                                                        : () => setState(
                                                            () => _choices[i] =
                                                                null,
                                                          ),
                                                    icon: const Icon(
                                                      Icons.clear,
                                                    ),
                                                  ),
                                          ),
                                          items: eligible
                                              .map(
                                                (n) => DropdownMenuItem(
                                                  value: n.id,
                                                  enabled: !_choices
                                                      .asMap()
                                                      .entries
                                                      .any(
                                                        (e) =>
                                                            e.key != i &&
                                                            e.value != null &&
                                                            event.nominees
                                                                    .firstWhere(
                                                                      (other) =>
                                                                          other
                                                                              .id ==
                                                                          e.value,
                                                                    )
                                                                    .uid ==
                                                                n.uid,
                                                      ),
                                                  child: Text(
                                                    n.label == n.name
                                                        ? n.name
                                                        : '${n.name} · ${n.label}',
                                                    style: TextStyle(
                                                      color:
                                                          _choices.asMap().entries.any(
                                                            (e) =>
                                                                e.key != i &&
                                                                e.value !=
                                                                    null &&
                                                                event.nominees
                                                                        .firstWhere(
                                                                          (
                                                                            other,
                                                                          ) =>
                                                                              other.id ==
                                                                              e.value,
                                                                        )
                                                                        .uid ==
                                                                    n.uid,
                                                          )
                                                          ? Theme.of(
                                                              context,
                                                            ).disabledColor
                                                          : null,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: _busy
                                              ? null
                                              : (v) => setState(() {
                                                  _choices[i] = v;
                                                }),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    FilledButton(
                                      onPressed:
                                          _busy || _choices.contains(null)
                                          ? null
                                          : () => _action(
                                              'vote',
                                              {
                                                'choices': List.of(_choices),
                                                'revision': event.revision,
                                              },
                                              'Enregistrer définitivement ce classement ?\n${List.generate(_choices.length, (i) {
                                                final n = event.nominees.firstWhere((n) => n.id == _choices[i]);
                                                return '${i + 1}. ${n.name} · ${n.label}';
                                              }).join('\n')}',
                                            ),
                                      child: const Text('Valider mon vote'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    )
                  else if (event.status == 'open')
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Tu peux consulter les nominations, mais tu ne fais pas partie des votants sélectionnés.',
                      ),
                    ),
                  if (event.status == 'closed') ...[
                    const SizedBox(height: 16),
                    if (event.results.isEmpty)
                      const Text('Aucun vote reçu : aucun trophée attribué.')
                    else ...[
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RevealScreen(ceremony: event),
                          ),
                        ),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Lancer la révélation'),
                      ),
                      ExpansionTile(
                        title: const Text('Afficher directement les résultats'),
                        children: [
                          for (final r in event.results)
                            ListTile(
                              leading: Text('${r.rank}'),
                              title: Text(r.nominee.name),
                              subtitle: Text(r.nominee.label),
                              trailing: Text('${r.points} pts'),
                            ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Les nominations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final n in event.nominees)
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(n.name),
                        subtitle: n.label == n.name ? null : Text(n.label),
                        children: [
                          if (n.videoId != null)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: YoutubeVideo(
                                key: ValueKey(n.videoId),
                                videoId: n.videoId!,
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Aucune vidéo pour cette nomination.',
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
    ),
  );
}
