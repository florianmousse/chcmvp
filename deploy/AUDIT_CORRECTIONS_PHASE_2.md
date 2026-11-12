# Corrections de l'audit complémentaire

Travail local du 10 novembre 2026. Aucun déploiement, envoi de notification réelle, modification de données de production ou publication Google Play n'a été effectué.

## Corrections

1. Le mailer refuse les invitations et réinitialisations si SMTP manque. Il émet un diagnostic de configuration sans destinataire ni lien. La route publique conserve sa réponse non discriminante. Les invitations ne prétendent plus avoir été envoyées dans ce cas.
2. Au démarrage puis toutes les dix minutes, une réconciliation parcourt les matchs par pages de 100. Les résultats incomplets ou périmés sont reconstruits ; une échéance manquante est initialisée sur les votes ouverts ordinaires. Les votes rouverts manuellement restent sans échéance automatique.
3. Le marqueur serveur `resultsSourceFingerprint` est enregistré seulement après la réussite du recalcul. Une modification concurrente empêche son acquittement et provoque une nouvelle tentative au cycle suivant. Les points sont reconstruits, jamais incrémentés lors d'une reprise. Une réouverture invalide le marqueur. `resultsRevision` suit les modifications de statistiques.
4. Les modifications de matchs clos et de statistiques recalculent les données dérivées, en production comme dans les espaces de validation. La réparation de fond reste silencieuse, y compris pour les badges. Les notifications de transition ne sont pas rejouées après une panne : elles peuvent être perdues, mais la reprise ne renvoie pas les anciens résultats à tout le club.
5. Les horaires utilisent explicitement Europe/Paris, indépendamment du fuseau du serveur. Les nouveaux clients transmettent `civilDate` au format `YYYY-MM-DD`. Le serveur valide cette date et conserve un Timestamp de compatibilité à midi dans le fuseau du club. Les nouveaux clients affichent la date civile sans conversion de fuseau. Les anciens documents gardent leur date existante, interprétée selon le calendrier de Paris : aucune migration massive des dates.
6. Une heure inexistante au passage à l'heure d'été est refusée. Pour l'heure répétée à l'automne, la première occurrence est retenue. Une ancienne date invalide est signalée et ignorée par le cycle automatique jusqu'à correction.
7. Les abonnements natifs aux tokens sont remplacés à chaque changement de compte et annulés à la déconnexion/destruction. Une initialisation devenue obsolète ne recrée pas d'abonnement. Les erreurs de synchronisation produisent un diagnostic sans données sensibles. Le token natif est invalidé avant la déconnexion ; le parcours web conserve sa propre invalidation existante.
8. Les profils de démarrage des espaces de review utilisent des identités synthétiques. Lors d'un accès, les anciennes copies de l'identité du propriétaire et du visiteur courant sont anonymisées une seule fois (`syntheticIdentityVersion: 1`), sans toucher à leurs profils racine ni aux matchs de validation. Les anciens visiteurs non revenus et les anciennes entrées de journal ne sont pas réécrits automatiquement : un nettoyage ciblé reste à planifier si ces données existent réellement.
9. Une liste de présence vide ne déclenche aucun rappel. L'ouverture côté API exige au moins trois joueurs distincts ; l'ouverture automatique revérifie la présence et l'horaire dans sa transaction.
10. Les fixtures Flutter des écrans de matchs utilisent les fournisseurs de saisons. Les assertions sur les votes, podiums, navigation et filtres sont conservées.

## Journal lisible

Le journal d'administration affiche des cartes avec action en français, objet lorsqu'il est connu, auteur, date, statut avec icône et changements avant/après. Les détails restent dépliables. Les erreurs et résultats inconnus sont distingués des réussites ; les champs inconnus ne sont jamais affichés comme du JSON brut. La recherche reconnaît aussi les libellés français et ne recrée pas l'abonnement Firestore à chaque frappe. Les permissions d'accès au journal restent inchangées.

Les principaux traitements serveur utilisent une ligne structurée : date UTC, niveau, événement, message, contexte opérationnel limité. Exemple synthétique :

```text
2026-11-10T10:30:00.000Z | INFO | vote.reparation | Résultats et classements recalculés sans notification. | matchId=exemple
```

`ATTENTION` et `ERREUR` permettent le filtrage dans les journaux systemd. Les messages de notification, noms des destinataires, liens de réinitialisation, bulletins et objets d'erreur externes ne sont pas transmis au nouveau logger.

## Icônes Android et web

- Android déclare `ic_stat_chc` comme icône FCM par défaut ; les notifications locales utilisaient déjà cette ressource monochrome sur fond transparent.
- Les deux chemins d'envoi serveur, notifications du club et badges, indiquent cette même icône. Une règle de conservation protège la ressource du nettoyage des ressources lors des builds.
- Sur le web, les messages indiquent `/logo.png` et un badge monochrome `/notification-badge.png`, copié depuis la même ressource existante. Les URL restent relatives à l'origine du service worker, sans domaine de production codé en dur.
- L'icône par défaut est configurée selon la [documentation Firebase Android](https://firebase.google.com/docs/cloud-messaging/android/get-started). Le badge web utilise les options de [WebpushNotification](https://firebase.google.com/docs/reference/admin/node/firebase-admin.messaging.webpushnotification).

## Vérifications

- Compilation TypeScript et 38 tests unitaires serveur réussis.
- 26 tests de règles Firestore et 55 tests d'intégration réussis sur émulateur local, projets `demo-*`. Les 55 tests d'intégration ont été rejoués après les derniers ajustements serveur. Aucun SDK de test n'a été dirigé vers la production.
- Analyse Flutter : aucun signalement. Suite Flutter : 131 tests réussis, dont la navigation clavier du journal et la compatibilité des dates civiles ; les tests ciblés du journal et des notifications ont également été rejoués avec les vraies polices du SDK.
- Rendus du composant de journal inspectés à 320 pixels en clair et 1100 pixels en sombre, avec texte agrandi à 150 %. Les quatre combinaisons clair/sombre et mobile/ordinateur passent sans débordement. Il s'agit de rendus de widgets, pas de parcours connectés sur un appareil ou navigateur réel.
- APK debug compilé avec `SERVER_BASE_URL=https://api.example.invalid`. Son manifeste compilé référence bien `ic_stat_chc` et ses cinq variantes sont présentes dans l'archive.
- Build web release réussi avec la même URL fictive ; le badge livré est identique au fichier source. Les cinq tests du service worker web passent. L'avertissement préexistant sur la police CupertinoIcons reste présent.
- Les avertissements Android sur les plugins `home_widget`, `package_info_plus`, `share_plus` et leur migration future de KGP restent présents. Aucune mise à jour majeure de dépendance n'a été forcée.

## Mise en service et retour arrière

1. Sauvegarder les données et conserver les livrables précédents dans le stockage privé habituel. Les nouveaux marqueurs sont additifs ; aucune règle Firestore n'est modifiée par cette phase.
2. Déployer le serveur avant les nouveaux clients : l'ancien serveur ne connaît pas `civilDate`. Vérifier SMTP, `/health` et les événements `vote.demarrage`, `vote.reparation` et `vote.reprise` dans les logs. La première réconciliation peut reconstruire les résultats historiques qui n'ont pas encore de marqueur ; prévoir la charge correspondante.
3. Déployer le web avec son nouveau badge, puis diffuser le client Android et le livrable de validation Google Play. Vérifier les comptes de review, leurs données synthétiques et l'absence d'envois aux membres depuis ces espaces.
4. Avant un nouvel envoi Play, vérifier le plus grand numéro de build utilisé et augmenter la version dans `pubspec.yaml`. Elle reste ici à `1.5.4+16` car aucun livrable destiné à publication n'a été demandé. Ne pas distribuer les builds de vérification qui utilisent `api.example.invalid`.
5. Vérifier une notification Android au premier plan, en arrière-plan et application fermée, barre repliée puis dépliée, sur un compte/appareil de test autorisé. Vérifier séparément Chrome/PWA et son badge. Aucun envoi réel n'a été effectué pendant ces corrections ; le rendu dans la barre Android et la réception FCM restent donc à confirmer sur appareil.
6. Si le retour arrière est nécessaire, revenir aux clients précédents avant de restaurer l'ancien serveur, sinon leurs requêtes contenant `civilDate` seront refusées. Conserver les données et marqueurs ajoutés : ne pas restaurer des règles d'accès plus permissives et ne pas réinjecter d'identités réelles dans les espaces de validation. Une réparation en avant est préférable pour préserver la reprise automatique.

La réconciliation répare les écritures dérivées de façon rejouable ; elle n'est pas une transaction globale sur tous les classements. Une panne au milieu d'une reconstruction peut exposer temporairement des données partielles jusqu'à la prochaine reprise. Les grandes reconstructions utilisent encore les mécanismes existants et méritent une surveillance de charge.
