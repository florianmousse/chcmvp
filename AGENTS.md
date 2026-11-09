# Consignes du projet

## Objectif et portée

- Traiter chaque modification comme du code destiné à la production et à un dépôt GitHub public, même si le projet porte encore le nom MVP.
- Ces consignes concernent tous les contributeurs et agents IA travaillant dans ce dépôt.
- Livrer du code maintenable, sécurisé, compréhensible et vérifié. Ne pas présenter une modification comme parfaite ou totalement sécurisée sans preuves : annoncer les contrôles réalisés et leurs limites.
- Ne pas laisser de simulation, de contournement temporaire, de données fictives ou de fonctionnalité incomplète dans un parcours de production. Isoler explicitement les fixtures et modes de démonstration.
- Adapter les vérifications au risque réel. Une correction documentaire ne nécessite pas une compilation complète ; une modification des permissions nécessite des tests de refus d'accès.

## Comprendre le projet avant de modifier

- Lire les consignes applicables, examiner `git status` et consulter les fichiers concernés avant toute modification.
- S'appuyer sur `README.md`, `ARCHITECTURE.md`, `pubspec.yaml`, `server/package.json` et les guides de `deploy/`. Vérifier les affirmations documentaires dans le code actuel : la documentation peut être ancienne.
- Respecter la stack existante : Flutter/Dart et Riverpod côté application, Node.js/Express/TypeScript côté serveur, Firebase pour les services utilisés.
- Respecter les responsabilités existantes entre `domain`, `data`, `presentation`, services partagés, routes et middleware. Garder les règles métier hors des widgets lorsque l'architecture le permet.
- Réutiliser les composants, modèles, validateurs, thèmes et services existants avant de créer une nouvelle abstraction.
- Corriger la cause du problème et ses usages concernés. Éviter les réécritures, déplacements et reformatages sans rapport avec la demande.

## Qualité et maintenance du code

- Privilégier une solution simple, explicite et cohérente avec le dépôt. Éviter les abstractions spéculatives et les dépendances inutiles.
- Utiliser des noms précis, des types explicites aux frontières et des fonctions aux responsabilités limitées.
- Éviter `dynamic`, `any`, les assertions de nullité et les conversions forcées quand une validation ou un type précis suffit.
- Ne pas masquer une erreur avec un `catch` vide, une valeur factice ou un succès apparent. Prévoir un traitement utile et un diagnostic sans données sensibles.
- Ne pas désactiver un lint, un test ou une protection pour faire passer une modification. Toute exception doit être étroite et justifiée.
- Supprimer le code mort introduit par la modification. Les commentaires doivent expliquer une contrainte ou une décision utile.
- Ne pas éditer à la main les fichiers générés. Modifier leur source et utiliser le générateur prévu lorsque nécessaire.
- Préserver la compatibilité des contrats API, modèles persistés et anciennes versions de l'application. Prévoir une migration explicite si une rupture est indispensable.

## Secrets et dépôt GitHub public

- Ne jamais ajouter au dépôt de mot de passe, jeton, clé privée, compte de service Firebase, secret SMTP, cookie de session, keystore ou configuration de signature privée.
- Ne pas afficher de secrets dans les réponses, commandes, journaux, captures, fixtures, exemples ou descriptions de pull request. Éviter de lire les fichiers de secrets si la tâche ne le nécessite pas.
- Conserver les secrets côté serveur dans les variables d'environnement ou un stockage adapté. Une valeur compilée dans Flutter ou envoyée au navigateur est accessible au client.
- Distinguer les identifiants publics de configuration Firebase des clés privées Firebase Admin. Ne jamais utiliser une configuration publique comme mécanisme d'autorisation.
- Fournir uniquement des exemples avec des valeurs fictives identifiables et documenter les variables nécessaires sans leurs valeurs réelles.
- Vérifier le diff et les fichiers suivis avant un commit ou une publication. Un fichier ignoré peut déjà être suivi ; `.gitignore` ne retire rien de l'historique.
- Si un secret est découvert dans le dépôt ou son historique, signaler son emplacement sans reproduire sa valeur. Une suppression ne suffit pas : prévoir sa révocation ou rotation avec le responsable. Ne pas réécrire l'historique partagé sans autorisation.
- Ne pas publier de données personnelles réelles, exports de base, sauvegardes, journaux de production ou captures identifiantes. Utiliser des données synthétiques dans les tests et démonstrations.
- Avant une publication publique, vérifier aussi les droits sur les images, logos et dépendances, ainsi que la cohérence de la licence et du README. Ne pas choisir une licence à la place du propriétaire ; dépôt public ne signifie pas automatiquement logiciel libre.

## Authentification, autorisation et entrées

- Considérer toutes les données du client comme non fiables, y compris les UID, rôles, équipes, dates et identifiants de ressources.
- Vérifier l'identité et les permissions côté serveur pour chaque opération protégée. Masquer un bouton ou protéger une route Flutter ne suffit pas.
- Appliquer le moindre privilège et refuser par défaut les opérations non autorisées. Vérifier l'accès à la ressource précise, pas seulement la présence d'un utilisateur connecté.
- Ne jamais accepter du client une élévation de rôle, une identité de votant arbitraire ou une écriture dans des champs calculés par le serveur.
- Valider les types, formats, tailles, plages de valeurs et champs autorisés. Éviter la copie aveugle d'un corps de requête dans la base.
- Préserver les protections contre les injections, le contenu HTML non sûr, les chemins arbitraires et les URL externes non contrôlées lorsque ces surfaces sont concernées.
- Limiter les requêtes abusives, volumes de données et opérations coûteuses sur les points d'entrée concernés. CORS ne remplace jamais l'authentification.
- Ne pas désactiver TLS, les contrôles de certificat ou les protections d'accès pour résoudre un problème de développement.
- Retourner au client une erreur exploitable sans exposer de pile technique, secret ou détail interne sensible.

## Firebase, votes et intégrité des données

- Pour chaque changement d'accès Firestore, examiner les règles et les chemins d'accès serveur concernés. Le SDK Admin contourne les règles Firestore : les contrôles du serveur restent indispensables.
- Préserver la confidentialité des votes individuels. Ne pas exposer à d'autres membres les choix d'un votant via une API, une requête, un journal ou un export.
- Préserver les invariants métier : éligibilité du votant et des joueurs, fenêtre de vote, unicité, choix distincts et politique de vote pour soi selon les paramètres du match.
- Garder les résultats, points et classements sous contrôle des chemins d'écriture autorisés. Vérifier les effets d'une réouverture, suppression ou recomputation.
- Utiliser des transactions, écritures atomiques ou mécanismes de concurrence adaptés pour les opérations sensibles. Un contrôle suivi d'une écriture indépendante peut permettre une course.
- Rendre les traitements rejouables et idempotents lorsque nécessaire : listeners, tâches planifiées, décompte des votes, notifications et reconstruction des classements.
- Préserver l'isolation des espaces de review, tests et démonstration : aucune écriture ni notification ne doit atteindre les vrais membres depuis ces espaces.
- Utiliser des instants et fuseaux explicites pour les échéances. Vérifier les limites de période, saisons et changements d'heure si le comportement temporel est modifié.
- Pour une migration ou une opération destructive, prévoir sauvegarde, vérification, reprise et retour arrière adaptés avant toute exécution sur des données réelles.

## Fiabilité, performances et expérience utilisateur

- Gérer les états de chargement, absence de données, erreur, déconnexion et permissions insuffisantes dans les parcours modifiés.
- Protéger les actions contre les doubles soumissions et gérer les opérations asynchrones après destruction d'un widget. Libérer les abonnements et ressources.
- Prévoir des délais d'attente et des reprises bornées pour les appels réseau. Ne pas rejouer automatiquement une écriture non idempotente.
- Éviter les lectures Firestore sans limite, les abonnements dupliqués, les boucles de requêtes et les recalculs coûteux dans les méthodes de rendu.
- Respecter les thèmes et composants existants, les tailles d'écran prises en charge, les zones sûres, la lisibilité et les messages en français.
- Pour les interfaces modifiées, vérifier les libellés accessibles, le contraste, l'agrandissement du texte et, sur le web, l'utilisation au clavier.
- Préserver la compatibilité web et mobile ; isoler les API propres à une plateforme.

## Dépendances, configuration et déploiement

- Justifier toute nouvelle dépendance et vérifier sa maintenance, sa compatibilité, sa licence et les risques connus pertinents. Conserver les fichiers de verrouillage cohérents.
- Ne pas lancer de mise à jour majeure ou de correction automatique forcée des dépendances sans en examiner les impacts.
- Ne pas ajouter une configuration spécifique à la machine du contributeur. Documenter les prérequis reproductibles et séparer les environnements.
- Si une configuration obligatoire manque, produire un diagnostic clair sans repli silencieux vers la production ni assouplissement des permissions.
- Pour les workflows GitHub ajoutés ou modifiés, limiter les permissions des jetons, protéger les secrets des contributions non fiables et épingler les actions tierces à des révisions vérifiées.
- Préparer les changements de déploiement avec leurs prérequis, leur vérification de fonctionnement et leur procédure de retour arrière.
- Une demande de modification de code n'autorise pas à elle seule une publication publique, un déploiement, un envoi de notifications réelles ou une mutation de données de production. Respecter les autorisations déjà données pour la tâche.

## Versions, Google Play et parité web

- Lorsqu'une nouvelle version de l'application doit être publiée, augmenter la valeur `version` dans `pubspec.yaml` avant de générer le livrable. Utiliser le format `X.Y.Z+N` et augmenter la version visible ainsi que le numéro de build `N`.
- Pour un nouvel envoi à Google Play, choisir un numéro de build supérieur aux numéros déjà utilisés sur les pistes concernées, y compris les pistes de test. Vérifier la dernière valeur publiée ou fournie par le responsable ; ne pas supposer que la valeur locale est la dernière utilisée.
- Centraliser la version dans `pubspec.yaml` et vérifier que le livrable Android App Bundle (`.aab`) destiné au Play Store correspond à cette version. Éviter les substitutions de version au moment du build qui laisseraient le dépôt incohérent.
- Ne pas augmenter la version à chaque simple modification : regrouper les changements dans la version à publier. Un nouveau livrable destiné à être envoyé après une version déjà utilisée doit recevoir un nouveau numéro de build.
- Toute évolution ou correction de l'application doit aussi être adaptée à la version web : logique métier, écrans, navigation, authentification et interactions. Prévoir un comportement web équivalent lorsque les API natives ne sont pas disponibles et signaler toute limitation réelle.
- Vérifier les parcours concernés sur Android et sur le web, notamment sur navigateur mobile et ordinateur lorsque l'interface change. Ne pas considérer une fonctionnalité terminée si son adaptation web reste à faire.
- Rendre également les nouvelles fonctionnalités et corrections disponibles à l'équipe de test et de validation Google Play, dans le livrable de test concerné et dans l'espace de review utilisé par ses comptes.
- Si une fonctionnalité utilise de nouvelles données, permissions, routes ou configurations, adapter aussi les fixtures synthétiques et les parcours de l'espace de review pour que les testeurs puissent réellement l'essayer, avec les mêmes règles métier et sans accès aux données réelles du club.
- Préserver l'isolation des comptes de review et la simulation des effets externes : l'accès aux nouvelles fonctionnalités ne doit pas provoquer d'envoi réel aux membres ni donner de privilèges sur la production.
- Avant une publication, vérifier ensemble la version, le contenu du livrable, la compatibilité web et l'accès aux parcours modifiés depuis les comptes de test Google Play. Documenter les vérifications impossibles ; ne pas annoncer leur réussite sans les avoir réalisées.

## Vérifications avant livraison

- Examiner le diff final pour détecter les régressions, modifications hors sujet, secrets et changements de permissions involontaires.
- Pour du Dart modifié, vérifier le format des fichiers concernés puis exécuter `flutter analyze` et les tests pertinents avec `flutter test`. Élargir aux tests complets si l'impact le justifie.
- Pour le serveur, exécuter `npm run build` puis `npm test` dans `server/` : les tests utilisent notamment les fichiers compilés dans `dist/`.
- Pour les scénarios serveur nécessitant Firestore, utiliser `npm run test:emulator` dans `server/` seulement après avoir vérifié la disponibilité et la configuration d'un émulateur local et d'un projet de test. Ne jamais utiliser la base de production pour ces tests.
- Une modification des règles Firestore exige des tests d'accès autorisé et refusé avec un client soumis aux règles. Les tests utilisant seulement le SDK Admin ne prouvent pas la validité des règles.
- Ajouter ou adapter des tests de comportement pour les corrections métier, permissions, concurrence et régressions significatives. Ne pas écrire un test qui reproduit simplement l'implémentation.
- Tester les cas limites pertinents : utilisateur anonyme ou inactif, mauvais rôle, ressource d'un autre utilisateur, données invalides, absence de données et répétition d'une action.
- Pour un changement visuel, inspecter si possible le rendu sur les formats concernés. Une compilation réussie ne valide pas l'affichage.
- Exécuter une compilation de la plateforme concernée lorsque des changements de dépendances, d'intégration native ou de configuration la rendent nécessaire.
- Pour une modification uniquement documentaire, vérifier le contenu, les chemins, les commandes et le diff ; ne pas lancer inutilement les suites applicatives.
- Ne jamais prétendre qu'un contrôle a réussi s'il n'a pas été exécuté. Signaler précisément les échecs, contrôles indisponibles et risques restant à vérifier.

## Git, documentation et communication

- Préserver le travail existant, y compris les modifications déjà indexées. Ne pas annuler, écraser ni réindexer les changements d'autrui sans nécessité autorisée.
- Éviter les commandes Git destructives, les ajouts globaux aveugles et les commits contenant des fichiers sans rapport avec la tâche.
- Mettre à jour la documentation concernée si un comportement, une commande, une variable, une API ou une procédure change.
- Rédiger les messages, commentaires et descriptions de pull request pour une personne qui ne connaît pas la conversation. Expliquer le problème, le comportement obtenu et les vérifications utiles.
- Communiquer en français, avec des faits précis. Distinguer les changements réalisés des propositions et des points restant à résoudre.
- Signaler les défauts importants découverts hors périmètre sans engager une refonte non demandée. Corriger de façon autonome les problèmes directement liés au travail autorisé.
- Avant de terminer, indiquer brièvement ce qui a changé, les vérifications effectuées et toute limite matérielle. Ne pas annoncer une mise en production ou une publication qui n'a pas eu lieu.

## Ponctuation

- Utiliser l'apostrophe droite ASCII `'` (U+0027), jamais l'apostrophe typographique U+2019.
- Utiliser le tiret simple ASCII `-` (U+002D), jamais le tiret cadratin U+2014.
- Appliquer ces règles aux textes de l'interface, à la documentation, aux commentaires et aux réponses aux utilisateurs.
- Préserver la syntaxe du code : échapper les apostrophes ou utiliser des chaînes entre guillemets doubles si nécessaire.
- Avant de terminer une modification, vérifier que les fichiers modifiés ne contiennent aucun de ces deux caractères interdits. Avec ripgrep : `rg -n '\x{2019}|\x{2014}' <fichiers>` (aucun résultat attendu).
