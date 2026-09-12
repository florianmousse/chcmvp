import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:chc_mvp/core/navigation/navigator_key.dart';
import 'package:chc_mvp/core/providers/messaging_providers.dart';
import 'package:chc_mvp/core/theme/app_theme.dart';
import 'package:chc_mvp/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';
import 'package:chc_mvp/features/auth/presentation/login_screen.dart';
import 'package:chc_mvp/features/home/presentation/home_screen.dart';
import 'package:chc_mvp/features/matches/presentation/matches_screen.dart';
import 'package:chc_mvp/features/profile/presentation/profile_screen.dart';
import 'package:chc_mvp/features/ranking/presentation/ranking_screen.dart';

// Généré par `flutterfire configure` — non inclus dans ce paquet, à créer
// en connectant le projet Firebase du club.
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR');
  try {
    // Obligatoire depuis google_sign_in v7, avant tout signInWithGoogle().
    await GoogleSignIn.instance.initialize();
  } catch (e) {
    // Ne bloque pas le démarrage de l'app si la config Google Sign-In
    // (SHA-1, google-services.json...) n'est pas encore en place — l'e-mail/
    // mot de passe reste utilisable, seul le bouton Google échouera.
    debugPrint('GoogleSignIn.initialize a échoué : $e');
  }
  runApp(const ProviderScope(child: HockeyClubApp()));
}

class HockeyClubApp extends ConsumerWidget {
  const HockeyClubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // messagingSyncProvider contient un ref.listen(authStateProvider, ...)
    // qui enregistre/retire le token FCM à la connexion/déconnexion — un
    // provider Riverpod est paresseux et ne s'active que si quelque chose le
    // lit. Sans cette ligne, ce mécanisme n'était tout simplement jamais
    // démarré, d'où fcmTokens qui restait vide indéfiniment.
    ref.watch(messagingSyncProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'CHC MVP',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr')],
      locale: const Locale('fr'),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _RootRouter(),
    );
  }
}

/// Bascule Connexion <-> Coquille principale (onglets) selon l'état d'auth,
/// avec un état intermédiaire pour un compte authentifié Firebase mais sans
/// fiche membre Firestore (ex: connexion Google avec un e-mail jamais
/// invité par l'admin) — sinon _MainShell planterait sur un profil manquant.
class _RootRouter extends ConsumerWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) =>
          user == null ? const LoginScreen() : const _AuthenticatedGate(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur : $e'))),
    );
  }
}

class _AuthenticatedGate extends ConsumerWidget {
  const _AuthenticatedGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    return profileAsync.when(
      data: (profile) => profile == null
          ? const _UnrecognizedAccountScreen()
          : const _MainShell(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur : $e'))),
    );
  }
}

class _UnrecognizedAccountScreen extends ConsumerWidget {
  const _UnrecognizedAccountScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Ce compte n'est associé à aucun membre du club.\nContacte un administrateur pour te faire inviter.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coquille avec navigation par onglets : Accueil, Matchs, Classements, Profil
/// (+ Administration si isAdminProvider)
class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Accueil',
      ),
      const NavigationDestination(
        icon: Icon(Icons.poll_outlined),
        selectedIcon: Icon(Icons.poll),
        label: 'Matchs',
      ),
      const NavigationDestination(
        icon: Icon(Icons.emoji_events_outlined),
        selectedIcon: Icon(Icons.emoji_events),
        label: 'Classements',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profil',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    // L'onglet Admin n'existe (à l'index 4) que si isAdmin est vrai ; s'il
    // vient de passer à false (démotion en direct) alors qu'on était dessus,
    // on se rabat sur Accueil pour ne pas pointer vers un onglet qui n'existe
    // plus dans la liste.
    final screens = [
      const HomeScreen(),
      const MatchesScreen(),
      const RankingScreen(),
      const ProfileScreen(),
      if (isAdmin) const AdminDashboardScreen(),
    ];
    final safeIndex = _index < screens.length ? _index : 0;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
