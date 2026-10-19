import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chc_mvp/core/widgets/responsive_content.dart';
import 'package:chc_mvp/features/auth/presentation/auth_providers.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});
  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  bool _web = kIsWeb;
  Widget section(
    String title,
    IconData icon,
    List<String> steps, {
    bool open = false,
  }) => Card(
    child: ExpansionTile(
      initiallyExpanded: open,
      leading: Icon(icon),
      title: Text(title),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('${i + 1}. ${steps[i]}'),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bien utiliser CHC MVP')),
    body: ResponsiveContent(
      maxWidth: 860,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Ton top 3 fait la différence',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Après chaque match, vote pour les trois joueurs qui se sont distingués. Retrouve ce guide à tout moment dans Profil → Tutoriel.',
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.android),
                label: Text('Android'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.language),
                label: Text('Site web'),
              ),
            ],
            selected: {_web},
            onSelectionChanged: (selection) =>
                setState(() => _web = selection.first),
          ),
          const SizedBox(height: 12),
          if (_web)
            section('Utiliser le site web', Icons.language, [
              'Ouvre https://chc-mvp.vercel.app/ dans ton navigateur. Utilise les mêmes identifiants que dans l’application Android : tes votes, résultats et badges sont partagés.',
              'Sur téléphone, navigue avec les onglets en bas. Sur ordinateur, utilise le menu à gauche. Une connexion Internet est nécessaire.',
              'Tu peux ajouter le site aux favoris ou à l’écran d’accueil si ton navigateur le propose. Le site ne reçoit pas de notifications push et ne propose pas les widgets Android : consulte l’onglet Matchs pour voir les votes ouverts.',
              'Un gestionnaire de mots de passe peut remplir la connexion. Vérifie que l’identifiant enregistré correspond à l’adresse du site. Sur un ordinateur partagé, déconnecte-toi depuis Profil.',
            ], open: true)
          else
            section('Utiliser l’application Android', Icons.android, [
              'Installe la version de CHC MVP distribuée par le club, puis ouvre l’application. Si tu as déjà utilisé le site, conserve les mêmes identifiants.',
              'Autorise les notifications si tu souhaites recevoir les ouvertures de vote, rappels et résultats. Si elles sont désactivées, vérifie les autorisations de CHC MVP dans les paramètres Android ; tu peux toujours voter depuis Matchs.',
              'Pour ajouter un widget, ouvre la liste des widgets depuis l’écran d’accueil du téléphone et cherche CHC MVP. Selon ton téléphone, un appui long permet d’y accéder. Les widgets affichent le prochain match, ton classement ou le dernier résultat ; ouvre l’application pour actualiser les données.',
              'Une connexion Internet est nécessaire. Mets l’application à jour avec la version fournie par le club. Son numéro est visible dans Profil.',
            ], open: true),
          section('1 · Se connecter', Icons.login, [
            'Un administrateur crée ta fiche et t’invite par e-mail. Utilise le lien reçu pour choisir ton mot de passe. Vérifie aussi les courriers indésirables.',
            'Connecte-toi avec ton adresse e-mail et ton mot de passe. En cas d’oubli, utilise « Mot de passe oublié » sur la page de connexion.',
            'Une fiche joueur sans e-mail permet de recevoir des votes, mais pas de se connecter ou de voter. Demande à un administrateur d’ajouter ton e-mail sur cette fiche pour activer ton accès sans perdre tes résultats.',
          ]),
          section('2 · Voter après un match', Icons.how_to_vote_outlined, [
            'Ouvre Matchs, puis le filtre « Vote ouvert ». Sur le match concerné, touche « Voter pour les 3 meilleurs joueurs ». Tu dois être inscrit parmi les joueurs présents.',
            'Choisis trois joueurs différents, dans l’ordre : meilleur joueur, deuxième, troisième. Tu ne peux voter pour toi-même que si l’administrateur a activé cette option.',
            'Vérifie tes choix avant « Valider mon vote ». Un vote réel est définitif : il ne peut être envoyé qu’une fois, avant la clôture. Le message « Vote enregistré, merci ! » confirme l’enregistrement, puis le match indique « Déjà voté ».',
            'Si tu ne peux pas voter, vérifie ta connexion, que le vote est encore ouvert et que ta présence a été renseignée. Contacte un administrateur si nécessaire. Le suivi admin indique qui n’a pas voté, jamais le top 3 choisi dans un bulletin réel.',
          ]),
          section(
            '3 · Résultats, statistiques et badges',
            Icons.emoji_events_outlined,
            [
              'Après la clôture, retrouve le podium dans Matchs et les classements dans Classements. Les points suivent le barème du match ; ils récompensent le podium final.',
              'Accueil résume les performances du club. Profil → Mes statistiques affiche ton parcours. Les buts, passes et cartons dépendent des feuilles renseignées par les admins.',
              'Dans Profil, les badges obtenus apparaissent en premier, les plus récents en tête. Touche un badge pour connaître sa condition et sa date d’obtention. Le serveur les recalcule : un badge peut être retiré si un match source est supprimé.',
              'Profil permet aussi de changer le thème, consulter le tutoriel et la version, puis se déconnecter.',
            ],
          ),
          if (ref.watch(isAdminProvider)) ...[
            section(
              'Admin · Préparer et gérer les matchs',
              Icons.edit_calendar_outlined,
              [
                'Dans Administration, crée les équipes et adversaires, puis les membres. L’e-mail est facultatif pour un joueur sans compte ; pour l’inviter plus tard, modifie sa fiche et utilise « Enregistrer et inviter ».',
                'Dans Administration → Matchs → Créer un match, renseigne la date, l’heure, l’équipe et l’adversaire. Le bouton + permet d’ajouter un adversaire. Coche les joueurs présents et vérifie l’option d’auto-vote. Sans auto-vote, il faut au moins quatre présents pour choisir trois autres joueurs.',
                'Le menu du match permet de modifier sa fiche, saisir les statistiques, ouvrir ou clôturer le vote. Les réglages du club pilotent également les ouvertures, rappels et clôtures automatiques.',
                'Sur chaque carte de match, « Voir le suivi » affiche le nombre de votants sur les présents et les noms des personnes n’ayant pas voté, même pendant le vote. Les fiches sans compte sont identifiées. Le suivi s’actualise toutes les 30 secondes ; « Actualiser » permet de vérifier immédiatement.',
                'Supprimer un match supprime aussi ses votes et ses points, puis recalcule les badges. Pour corriger des données anciennes, utilise « Reconstruire les classements maintenant » dans Administration.',
              ],
            ),
            section(
              'Admin · Essayer sans toucher aux classements',
              Icons.science_outlined,
              [
                'Active « Match de test » lors de la création. Les tests ne sont visibles que des admins et leurs notifications ne ciblent que les admins. Ils ne comptent pas pour les classements, statistiques ou badges du club.',
                'Dans le menu du test, choisis « Simuler les votes / résultats ». Ouvre le vote, sélectionne le joueur qui vote et son top 3, puis enregistre. Un nouvel enregistrement remplace son bulletin pour ce test uniquement.',
                'Clôture le test pour calculer les résultats. Tu peux le rouvrir ou le supprimer. La simulation n’est jamais disponible sur un vrai match.',
              ],
            ),
          ],
          const SizedBox(height: 16),
          const SelectableText(
            'Besoin d’aide ?\nchcmvp.chateaubourghockeyclub@gmail.com',
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}
