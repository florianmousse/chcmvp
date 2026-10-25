# Bien utiliser CHC MVP - Android et site web

Ce tutoriel est aussi disponible dans **Profil → Tutoriel**. Les mêmes identifiants, votes, résultats et badges fonctionnent sur Android et sur le [site du club](https://chc-mvp.vercel.app/). Une connexion Internet est nécessaire.

## Première connexion

1. Un administrateur crée ta fiche et t'invite par e-mail. Ouvre le lien reçu pour choisir ton mot de passe. Vérifie les courriers indésirables si tu ne trouves pas le message.
2. Connecte-toi avec ton adresse e-mail et ton mot de passe. Utilise **Mot de passe oublié** si nécessaire.
3. Une fiche sans e-mail permet de recevoir des votes mais pas de se connecter ou de voter. Demande à un administrateur d'ajouter ton e-mail à cette même fiche : tes résultats seront conservés.

## Sur Android

- Installe la version de CHC MVP distribuée par le club et connecte-toi.
- Autorise les notifications pour les ouvertures de vote, rappels et résultats. Vérifie les autorisations de CHC MVP dans les paramètres Android si tu ne reçois rien. Tu peux toujours consulter les votes ouverts dans **Matchs**.
- Dans la liste des widgets de ton écran d'accueil, cherche CHC MVP pour ajouter le prochain match, ton classement ou le dernier résultat. Selon ton téléphone, un appui long sur l'écran d'accueil permet d'ouvrir cette liste. Ouvre l'application pour actualiser leurs données.
- Mets l'application à jour avec la version fournie par le club. Son numéro est consultable dans **Profil → Version de l'application**.

## Sur le site web

- Ouvre [CHC MVP](https://chc-mvp.vercel.app/) dans ton navigateur. Sur téléphone, les onglets sont en bas ; sur ordinateur, la navigation est à gauche.
- Ajoute le site aux favoris ou à l'écran d'accueil si ton navigateur le propose.
- Le site ne propose pas de notifications push ni de widgets Android. Consulte **Matchs → Vote ouvert** pour savoir quand voter.
- Un gestionnaire de mots de passe peut remplir la connexion : vérifie que l'identifiant enregistré correspond bien au domaine du site. Sur un appareil partagé, déconnecte-toi depuis **Profil**.

## Voter pour un match

1. Dans **Matchs → Vote ouvert**, choisis **Voter pour les 3 meilleurs joueurs**. Ta présence au match doit avoir été renseignée.
2. Sélectionne trois joueurs différents, dans l'ordre : meilleur joueur, deuxième, troisième. L'auto-vote dépend du réglage choisi par l'admin.
3. Vérifie tes choix avant **Valider mon vote** : tu ne peux pas modifier toi-même un bulletin enregistré. En cas d'erreur, demande à un admin de le réinitialiser pendant que le vote est ouvert, puis vote à nouveau.
4. Attends **Vote enregistré, merci !**, puis l'indication **Déjà voté**. En cas de problème, vérifie Internet et l'ouverture du vote ; demande à l'admin de vérifier ta présence.

Les administrateurs peuvent voir la participation et les noms des personnes qui n'ont pas voté. Le suivi de l'application ne révèle pas les choix des bulletins réels.

## Résultats, statistiques et badges

- Après la clôture, le podium apparaît dans **Matchs** et les points dans **Classements**. Le barème du match récompense le podium final.
- **Accueil** résume les performances du club ; **Profil → Mes statistiques** présente ton parcours. Les buts, passes et cartons proviennent des feuilles saisies par les admins.
- Dans **Profil**, les badges obtenus sont affichés en premier, les plus récents en tête. Touche un badge pour lire sa condition et sa date d'obtention. La suppression d'un match peut entraîner le retrait d'un badge qui n'est plus justifié.
- Le profil contient aussi le thème, le tutoriel, le numéro de version et la déconnexion.

## Pour les administrateurs

1. Dans **Administration**, prépare les équipes, adversaires et membres. Pour inviter plus tard un joueur sans e-mail, modifie sa fiche et choisis **Enregistrer et inviter**.
2. Dans **Matchs → Créer un match**, renseigne date, heure, équipe, adversaire et joueurs présents. Le bouton **+** ajoute un adversaire. Sans auto-vote, prévois au moins quatre présents pour que chacun puisse choisir trois autres joueurs.
3. Le menu du match permet de modifier sa fiche, saisir les statistiques, ouvrir ou clôturer le vote. Les réglages du club pilotent aussi les ouvertures, rappels et clôtures automatiques.
4. Sur chaque carte de match et dans la liste d'administration, **X / Y ont voté → Voir le suivi** affiche les personnes qui n'ont pas encore voté, même pendant le vote. Le total correspond aux joueurs présents : les fiches sans compte et les comptes désactivés sont signalés. Le suivi se recharge toutes les 30 secondes ; **Actualiser** permet une vérification immédiate.
5. Pour essayer la procédure, crée un **Match de test**, puis utilise son menu **Simuler les votes / résultats**. Choisis le votant et son top 3. Tu peux remplacer ses bulletins simulés, clôturer et rouvrir le test. Les tests et leurs notifications sont réservés aux admins et n'affectent pas les performances du club.
6. Supprimer un match supprime ses votes et ses points puis recalcule les badges. Pour corriger des données anciennes, utilise **Reconstruire les classements maintenant**.

### Rouvrir un vote terminé

Dans **Administration → Matchs**, ouvre le menu du match et choisis **Rouvrir le vote**. Les bulletins existants restent enregistrés : sur un vrai match, seuls les joueurs n'ayant pas encore voté peuvent ajouter un bulletin. Le match est retiré du classement, des statistiques agrégées et du calcul des badges jusqu'à sa nouvelle clôture.

Le libellé **Vote rouvert · clôture manuelle** indique qu'aucune clôture automatique n'aura lieu, même après un redémarrage du serveur. Utilise **Clôturer le vote** pour finaliser les résultats. Le serveur rappelle cette action aux admins dès son prochain passage (au plus 10 minutes), puis toutes les 24 heures. Les notifications push nécessitent un appareil Android enregistré et l'autorisation de notification ; le site web affiche l'état du match sans notification push. Les rappels s'arrêtent à la clôture ou à la suppression.

Les matchs de test suivent la même clôture manuelle après réouverture ; leurs bulletins simulés restent modifiables et leurs rappels sont préfixés **[TEST]**. Ils n'affectent jamais le classement du club.

Les classements n'affichent que les joueurs ayant gagné des points. Un joueur hors podium peut avoir reçu des votes sans gagner de point : ses votes restent comptés dans ses statistiques.

### Corriger le vote d'un joueur

Avec un compte admin, ouvre **Voir le suivi → Ont voté** sur le match, puis **Réinitialiser le vote** sous le nom du joueur. Une confirmation rappelle le joueur concerné. Seul son bulletin est supprimé : les autres votes et la fiche du match restent intacts. Le joueur réapparaît dans **En attente** et son bouton **Voter** redevient disponible.

La période de vote doit être ouverte. Un match terminé doit d'abord être rouvert ; il faudra alors le clôturer manuellement comme expliqué ci-dessus. La réinitialisation ne prolonge pas le délai d'un vote ordinaire. Elle ne révèle jamais les choix du joueur.

Le suivi présente les noms en gras dans des cartes distinctes. Dans **En attente**, les joueurs sans compte sont regroupés à la fin de la liste ; ils restent inclus dans le total des présents. **Ont voté** affiche les auteurs des bulletins enregistrés, sans leur contenu.

Contact du club : chcmvp.chateaubourghockeyclub@gmail.com.
