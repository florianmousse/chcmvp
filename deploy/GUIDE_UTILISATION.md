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

À la réouverture d'un vrai match, seuls les participants qui n'ont pas encore voté reçoivent une invitation à voter. À la nouvelle clôture, tous les participants reçoivent une notification **Classement actualisé** pour consulter les résultats recalculés avec les votes tardifs, y compris ceux qui avaient déjà voté.

Les classements affichent les joueurs ayant gagné des points et les membres actifs ayant obtenu un badge ou un trophée. Ces derniers peuvent apparaître à **0 point**, sans numéro de rang. Un joueur hors podium peut avoir reçu des votes sans gagner de point : ses votes restent comptés dans ses statistiques.

### Corriger le vote d'un joueur

Avec un compte admin, ouvre **Voir le suivi → Ont voté** sur le match, puis **Réinitialiser le vote** sous le nom du joueur. Une confirmation rappelle le joueur concerné. Seul son bulletin est supprimé : les autres votes et la fiche du match restent intacts. Le joueur réapparaît dans **En attente** et son bouton **Voter** redevient disponible.

La période de vote doit être ouverte. Un match terminé doit d'abord être rouvert ; il faudra alors le clôturer manuellement comme expliqué ci-dessus. La réinitialisation ne prolonge pas le délai d'un vote ordinaire. Elle ne révèle jamais les choix du joueur.

Le suivi présente les noms en gras dans des cartes distinctes. Dans **En attente**, les joueurs sans compte sont regroupés à la fin de la liste ; ils restent inclus dans le total des présents. **Ont voté** affiche les auteurs des bulletins enregistrés, sans leur contenu.

### Organiser une cérémonie

Depuis **Accueil → Cérémonies** ou **Administration → Cérémonies**, crée un prix : Ballon d'or, Golden Boy, Puskás, plus belle passe décisive ou prix personnalisé. Pour une soirée avec plusieurs prix, crée une cérémonie par prix et précise l'édition dans chaque titre.

1. Pour Ballon d'or et Golden Boy, sélectionne simplement les joueurs : aucun titre de nomination à répéter. Choisis un top de **1 à 10**, les nominations et les membres autorisés à voter. Un joueur sans compte peut recevoir un prix. Pour Golden Boy, l'admin choisit lui-même les joueurs éligibles.
2. Pour une action, indique un titre et éventuellement un lien YouTube public ou non répertorié dont l'intégration est autorisée. Plusieurs actions du même joueur peuvent être nommées. Assure-toi d'avoir les autorisations des personnes filmées.
3. Sans auto-vote, chaque votant doit avoir assez de nominations appartenant à d'autres joueurs pour remplir son top. Crée le brouillon, vérifie sa fiche, puis **Ouvrir le vote**. Les brouillons sont réservés aux admins.
4. Les joueurs déjà choisis sont grisés dans les autres places. Utilise la croix pour libérer une place avant de déplacer un joueur. Chaque votant remplit son classement avec un seul choix par joueur et confirme son bulletin. Un top 5 donne 5, 4, 3, 2 et 1 point aux choix. Aucun point n'est ajouté au classement des matchs.
5. Utilise **Clôturer et révéler** : les résultats sont publiés et les premiers reçoivent leur trophée. La révélation part du dernier rang du top jusqu'au premier, avec avance manuelle, lecture automatique et possibilité de rejouer. Elle n'est pas synchronisée entre les appareils ; pour une soirée, projette un écran commun.

À points égaux, le nombre de premières places départage les nominations, puis celui des places suivantes. Une égalité parfaite conserve un rang commun et tous les premiers reçoivent le trophée. Sans vote, aucun trophée n'est attribué. Seules les nominations ayant reçu des points apparaissent dans les résultats.

Une cérémonie peut être annulée avant sa clôture. Les admins disposent de **Modifier**, **Rouvrir le vote** et **Supprimer**. Modifier préremplit le formulaire (y compris les vidéos) ; enregistrer exige une confirmation et remet tous les votes à zéro, retire les trophées puis repasse la cérémonie en brouillon. Rouvrir conserve les bulletins valides et retire les trophées jusqu'à la prochaine clôture manuelle. Les anciens bulletins avec plusieurs choix pour le même joueur sont invalidés à la réouverture afin de pouvoir être refaits. Supprimer efface définitivement la cérémonie, tous ses bulletins et ses trophées après confirmation. Sur Android, les votants actifs reçoivent une notification d'ouverture ou de réouverture seulement s'ils doivent encore voter. À la clôture, les votants et nominés actifs reçoivent une annonce des résultats sans dévoiler le gagnant. Toucher la notification ouvre la cérémonie. Les notifications doivent être autorisées sur l'appareil ; le web ne reçoit pas de push.

### Regarder les vidéos et consulter les distinctions

Dans une cérémonie, ouvre une nomination puis **Autoriser YouTube pour cette vidéo** pour afficher le lecteur intégré. Ce choix est facultatif et limité au lecteur ouvert. Sur Android, **Réessayer la vidéo** recharge le lecteur ; **Lire dans le navigateur intégré** offre une autre façon de la regarder. **Fermer le lecteur YouTube** le retire. **Ouvrir YouTube** reste disponible si la lecture intégrée échoue. Il est possible de voter sans charger les vidéos.

Les **Trophées de cérémonie** ont leur propre section sur le profil et sur la fiche d'un joueur. Les badges restent des récompenses de progression. Les badges **Buteur** et **Passeur** possèdent trois paliers : **bronze à 5**, **argent à 15**, **or à 25** buts ou passes dans une même saison. Seul le meilleur palier obtenu est affiché par badge. Les saisons ne s'additionnent pas ; un palier obtenu lors d'une saison précédente reste conservé tant que ses matchs le justifient.

**Couteau suisse** récompense les buts ET les passes, sans valoriser les cartons : bronze à **3 + 3**, argent à **8 + 8**, or à **15 + 15** dans une saison. **En feu** demande 3 matchs joués consécutifs dans le top 3. **Révélation** compare la moyenne des matchs suivants aux 3 premiers de la saison (hausse de 40 %, au moins 4 matchs, moyenne initiale non nulle). **Podium Master** demande 5 premières places et **Centurion** 30 points par saison.

Les corrections ou suppressions de matchs peuvent abaisser un palier ou retirer un badge. Elles ne retirent pas un trophée de cérémonie, dont le résultat est indépendant. Les distinctions apparaissent à côté du nom dans le classement ; leur détail reste consultable sur le profil.

**Cap des 50** est un badge de parcours : il récompense 50 points de classement cumulés sur toutes les saisons. Les matchs de test et les points des cérémonies sont exclus. Il peut être retiré si une correction ou suppression de match fait repasser le total sous 50. Il est distinct de Centurion, qui demande 30 points dans une même saison.

### Types de matchs et changements d'e-mail

Dans **Administration → Matchs**, choisis **Championnat** (bleu), **Amical** (gris) ou **Playoff** (vert). Les anciens matchs sont Championnat. Un amical propose le vote MVP, les notifications de vote et le suivi de participation habituels. Après clôture, sa carte affiche le top 3 et le nombre de votants. Ce podium reste amical : aucun point officiel, statistique, badge ou bilan ne lui est attribué ; il reste absent des résumés de l'accueil et des widgets. Son score peut être saisi. Les actions **Ouvrir**, **Clôturer** et **Rouvrir le vote** fonctionnent comme pour les autres matchs. Passer un ancien match en amical retire ses contributions officielles tout en conservant ses votes et son podium local.

Dans **Administration → Membres → Modifier**, une adresse e-mail existante peut être remplacée. L'adresse doit être libre. Le même compte est conservé, avec son mot de passe, ses votes, statistiques, badges et trophées. Il faudra utiliser la nouvelle adresse pour la prochaine connexion par e-mail. Pour un joueur sans compte, utilise toujours **Enregistrer et inviter**.

Contact du club : chcmvp.chateaubourghockeyclub@gmail.com.

## Filtrer les matchs par saison

Dans **Matchs**, le sélecteur **Saison** propose uniquement les saisons contenant des matchs (septembre à août). La saison courante est sélectionnée si elle contient des matchs, sinon la plus récente disponible. La liste des saisons est obtenue en lisant un seul match par saison, sans charger tout l'historique. Seuls les matchs de la saison sélectionnée sont chargés par cet écran. Les votes ouverts apparaissent en premier, du match le plus récent au plus ancien. Les autres matchs suivent, également par date décroissante, sans séparation entre matchs à venir et terminés. Les filtres de statut restent disponibles. Ce fonctionnement est identique sur Android, sur le web et dans les espaces de review.
