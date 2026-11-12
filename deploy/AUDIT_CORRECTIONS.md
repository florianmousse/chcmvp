# Corrections de l'audit des consignes

## Comportement

- Les membres lisent l'annuaire via `GET /members/directory`, par pages de 100 avec un curseur opaque pour le client. La projection exclut les tokens et tous les champs non explicitement autorisés. Les e-mails ne sont retournés qu'aux administrateurs actifs, notamment pour sélectionner les votants des cérémonies. Les comptes `reviewer` sont exclus de l'annuaire du club.
- Les documents Firestore `users` complets sont réservés à leur propriétaire et aux administrateurs actifs. Aucun document ni compte n'est déplacé ou supprimé. Les espaces de validation utilisent la même route avec leur base isolée ; les administrateurs de ces espaces ne reçoivent que leurs données de démonstration.
- L'annuaire est actualisé à l'ouverture de son flux puis toutes les minutes, avec une seule requête en cours par flux et arrêt du minuteur à son annulation. Une panne est affichée comme une erreur, jamais comme une liste vide. La liste de gestion des administrateurs reste en temps réel.
- Les listes de matchs et la liste de gestion des membres utilisent des abonnements paginés de 100 documents, ordonnés par identifiant. Une insertion ou suppression qui déplace une frontière recharge les pages suivantes. Une liste partielle n'est pas publiée aux calculs métier. L'historique complet reste nécessaire aux statistiques existantes : le volume total reste proportionnel à cet historique, même si chaque requête est bornée. Cette correction ne remplace pas les statistiques historiques par une agrégation serveur.
- Les modifications de profil refusent les noms/équipes vides ou de plus de 120 caractères, les numéros hors de 0 à 999 et les photos autres que des URL HTTPS de 2048 caractères maximum, sans identifiants intégrés. `null` permet de retirer une photo ou un numéro.
- Les tokens FCM sont des listes de dix chaînes distinctes maximum, de 1 à 4096 caractères sans espaces. Android et web les mettent à jour par transaction et gardent les dix appareils enregistrés le plus récemment. Les données anciennes mal formées sont normalisées lors de cette opération ; le serveur ignore les tokens invalides sans interrompre les notifications des autres membres.
- Les appels HTTP GET, POST et DELETE expirent après 20 secondes, authentification comprise. Les écritures ne sont pas rejouées. Après une coupure, vérifier le résultat avant de réessayer : un délai client ne prouve pas que le serveur a annulé l'action.
- La réinitialisation publique du mot de passe valide l'adresse et limite les demandes sur 15 minutes : 3 par adresse, 10 par IP et 100 au total. Les réponses pour un compte absent et un envoi échoué restent identiques. Le contrôleur ne journalise ni adresse ni lien ; la fuite complémentaire identifiée dans le mailer sans SMTP est corrigée localement dans la [deuxième phase](AUDIT_CORRECTIONS_PHASE_2.md), dont le déploiement reste à effectuer.

## Configuration obligatoire

`SERVER_BASE_URL` n'a plus de valeur de production par défaut. Utiliser une URL HTTPS sans chemin, identifiants, query string ou fragment ; HTTP est admis uniquement sur localhost/loopback pour le développement. Une application mal configurée affiche un diagnostic avant toute initialisation Firebase.

```powershell
flutter run --dart-define=SERVER_BASE_URL=https://api.example.invalid
flutter build web --release --dart-define=SERVER_BASE_URL=https://api.example.invalid
flutter build appbundle --release --dart-define=SERVER_BASE_URL=https://api.example.invalid
```

Remplacer le domaine fictif par celui de l'environnement visé. Sur Vercel, définir explicitement la variable avant le build. Aucun changement de version n'est nécessaire pour les tests locaux ; avant un envoi Play, vérifier les builds déjà utilisés et augmenter `pubspec.yaml` selon le guide de publication.

Le limiteur de réinitialisation est en mémoire, pour le serveur mono-processus existant. Un redémarrage remet les compteurs à zéro. Avant plusieurs processus ou instances, installer un limiteur partagé en amont. Express ne fait confiance qu'aux proxies loopback : conserver Nginx local, ne pas ouvrir directement le port du backend et écraser les en-têtes transférés au proxy. Une autre topologie nécessite une configuration explicite des proxies de confiance.

## Mise en service et compatibilité

Les anciens clients qui lisent directement toutes les fiches `users` ne sont pas compatibles avec les nouvelles règles. La fermeture de ces lectures est nécessaire pour supprimer l'exposition des coordonnées et tokens : ne pas déployer les règles seules.

1. Sauvegarder les règles actuellement déployées et conserver le livrable serveur/client précédent dans le stockage privé de déploiement. Cette procédure ne nécessite aucune mutation des données membres.
2. Déployer le backend avec la route d'annuaire, puis vérifier celle-ci avec des comptes de test autorisés. Contrôler le proxy et les seuils HTTP 429 sans envoyer de messages à des membres réels.
3. Publier les clients Android et web configurés, ainsi que le livrable de validation Google Play. Tester dans l'espace de review : membres, profils, sélection des votants, vote, classement et notifications simulées.
4. Organiser la mise à jour obligatoire des anciennes versions avant de déployer les nouvelles règles. Aucune infrastructure de blocage des anciennes versions n'est ajoutée ici : cette étape doit être organisée par le responsable de publication.
5. Déployer les règles seulement après validation des clients. Vérifier qu'un membre lit sa propre fiche mais ne lit plus les fiches complètes d'autrui, qu'un administrateur conserve sa gestion et qu'un compte de validation reste isolé.
6. Tester les mises à jour des tokens sur Android et sur le web, ainsi que l'absence de requête vers la production si la configuration est absente.

En cas d'échec avant la fermeture des règles, suspendre la mise en service et revenir aux livrables précédents. Après fermeture, conserver les règles privées et corriger le client/backend en avant ; restaurer les anciennes règles réexposerait les données et nécessite une décision explicite du responsable. Ne pas annoncer la correction de production avant ce déploiement coordonné.

## Vérifications reproductibles

```powershell
npm --prefix server run build
npm --prefix server test
flutter analyze --no-pub
flutter test --no-pub
firebase emulators:exec --config firestore/emulator.json --project demo-chc-web --only firestore "node --test firestore/vote-rules.test.mjs server/test/rankings.emulator.test.cjs server/test/ceremonies.emulator.test.cjs server/test/review-audit.emulator.test.cjs server/test/review-space.emulator.test.cjs server/test/security-boundaries.emulator.test.cjs"
```

Java 21+ et les connexions loopback doivent être disponibles. Ces tests utilisent uniquement des projets `demo-*`. Les tests unitaires de réinitialisation injectent un expéditeur synthétique, sans SMTP. Les contrôles de production, les comptes Play réels et la publication restent des étapes séparées.

## Résultats de la vérification locale

- Analyse Flutter : aucun signalement ; format des 26 fichiers Dart concernés vérifié.
- Suite Flutter : 115 tests réussis, y compris les quatre échecs de l'audit initial et la fermeture de l'écran pendant un vote qui échoue.
- Serveur : compilation TypeScript et 34 tests unitaires réussis.
- Émulateur : 75 tests de règles et d'intégration réussis, dont les accès refusés aux profils et aux tokens. Les 9 tests ciblant l'annuaire et l'espace de validation ont été rejoués après l'ajustement des contacts visibles par les admins.
- Compilations web release et Android debug réussies avec `SERVER_BASE_URL=https://api.example.invalid`. Ces fichiers sont des livrables de vérification, pas des versions à publier.
- Avertissements de compilation à reprendre lors de l'audit complémentaire : police CupertinoIcons attendue sur le web ; plugins `home_widget`, `package_info_plus` et `share_plus` utilisant encore KGP sur Android. Ils n'ont pas bloqué ces builds et aucune mise à jour de dépendance n'a été forcée.
- Diff et ponctuation vérifiés. Aucun déploiement, envoi Play, e-mail réel ni modification de données de production. Les parcours sur appareil réel et navigateur connecté restent à valider lors de la mise en service.
