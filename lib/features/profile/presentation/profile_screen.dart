import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/foundation.dart';
import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:chc_mvp/core/widgets/legal_links.dart';
import 'package:chc_mvp/core/widgets/app_version_tile.dart';
import 'package:chc_mvp/features/help/presentation/help_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/badges/presentation/badges_providers.dart';
import 'package:chc_mvp/core/theme/theme_provider.dart';
import 'package:chc_mvp/features/home/presentation/badges_section.dart';
import 'package:chc_mvp/features/home/domain/badge_model.dart';
import 'package:chc_mvp/features/ranking/presentation/player_stats_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null)
            return const SizedBox.shrink(); // gardé par _AuthenticatedGate

          final identity = <Widget>[
            CircleAvatar(
              radius: 40,
              backgroundImage: profile.photoUrl != null
                  ? NetworkImage(profile.photoUrl!)
                  : null,
              child: profile.photoUrl == null
                  ? Text(
                      profile.firstName.isNotEmpty ? profile.firstName[0] : '?',
                      style: const TextStyle(fontSize: 28),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Text(profile.team, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('E-mail'),
              subtitle: Text(profile.email),
            ),
            if (profile.jerseyNumber != null)
              ListTile(
                leading: const Icon(Icons.numbers),
                title: const Text('Numéro de maillot'),
                subtitle: Text('#${profile.jerseyNumber}'),
              ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Mes statistiques'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerStatsScreen(
                    uid: profile.uid,
                    playerName: profile.fullName,
                  ),
                ),
              ),
            ),
          ];
          if (MediaQuery.sizeOf(context).width >= 1100) {
            return ResponsiveContent(
              maxWidth: 1200,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              ...identity,
                              const _HelpAndVersion(),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.logout),
                                label: const Text('Se déconnecter'),
                                onPressed: () =>
                                    ref.read(authServiceProvider).signOut(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: _BadgesWrapper(uid: profile.uid),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: _ThemeSelector(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const LegalLinks(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: profile.photoUrl != null
                    ? NetworkImage(profile.photoUrl!)
                    : null,
                child: profile.photoUrl == null
                    ? Text(
                        profile.firstName.isNotEmpty
                            ? profile.firstName[0]
                            : '?',
                        style: const TextStyle(fontSize: 28),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Center(
                child: Text(
                  profile.team,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),

              // ── Badges ──
              _BadgesWrapper(uid: profile.uid),

              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('E-mail'),
                subtitle: Text(profile.email),
              ),
              if (profile.jerseyNumber != null)
                ListTile(
                  leading: const Icon(Icons.numbers),
                  title: const Text('Numéro de maillot'),
                  subtitle: Text('#${profile.jerseyNumber}'),
                ),
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Mes statistiques'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerStatsScreen(
                      uid: profile.uid,
                      playerName: profile.fullName,
                    ),
                  ),
                ),
              ),
              const Divider(height: 32),
              const _HelpAndVersion(),

              // ── Thème ──
              _ThemeSelector(),

              if (kIsWeb) ...[
                const SizedBox(height: 24),
                const Text(
                  "Sur le web, consulte les votes et résultats dans l'application. "
                  "Les notifications push et les widgets d'écran d'accueil restent disponibles dans l'application mobile.",
                ),
                const SizedBox(height: 12),
                const LegalLinks(),
              ],

              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
    );
  }
}

class _HelpAndVersion extends StatelessWidget {
  const _HelpAndVersion();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Tutoriel'),
        subtitle: const Text('Bien utiliser l’application et le site web'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
      ),
      const AppVersionTile(),
    ],
  );
}

/// Les badges sont recalculés par le serveur : le client ne peut pas rétablir
/// un badge retiré après la suppression d'un match.
class _BadgesWrapper extends ConsumerWidget {
  const _BadgesWrapper({required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Celebrate server additions only; never write or restore local badges.
    ref.listen(userBadgesProvider(uid), (previous, next) {
      if (previous?.hasValue != true || !next.hasValue) return;
      final added = Badge.allDefinitions.values
          .where(
            (badge) =>
                next.value!.containsKey(badge.type.name) &&
                !previous!.value!.containsKey(badge.type.name),
          )
          .toList();
      if (added.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showModalBottomSheet<void>(
          context: context,
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    added.length == 1
                        ? 'Nouveau badge débloqué !'
                        : '${added.length} nouveaux badges !',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final badge in added)
                    ListTile(
                      leading: Text(
                        badge.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(badge.label),
                      subtitle: Text(badge.description),
                    ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Super ! 🙌'),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    });
    return ref
        .watch(userBadgesProvider(uid))
        .when(
          data: (dates) =>
              BadgesSection(earnedBadges: const [], earnedDates: dates),
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const Text('Badges indisponibles pour le moment.'),
        );
  }
}

/// Sélecteur de thème (Système / Clair / Sombre) avec un SegmentedButton.
class _ThemeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Text('Thème', style: theme.textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Système'),
                  icon: Icon(Icons.settings_brightness),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Clair'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Sombre'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {current},
              onSelectionChanged: (selected) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(selected.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}
