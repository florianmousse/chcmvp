# Version 1.4.1 (11) - Corrections des cérémonies et des badges

## Cérémonies

- Un joueur ne peut apparaître qu'une seule fois dans un bulletin, même si plusieurs de ses actions sont nominées. La règle est vérifiée dans l'application et sur le serveur. Choisir un joueur déjà classé échange les places sans dupliquer le joueur.
- La création vérifie qu'il existe assez de **joueurs différents** accessibles à chaque votant pour remplir le top, en tenant compte de l'auto-vote.
- **Rouvrir le vote** est disponible pour les admins sur une cérémonie clôturée ou annulée. Les bulletins valides restent enregistrés ; seuls les votants sans bulletin valide votent à nouveau. Les résultats et trophées disparaissent jusqu'à la prochaine clôture manuelle.
- **Modifier** préremplit titre, catégorie, taille du top, auto-vote, nominations, vidéos et votants. Chaque nomination peut être éditée ou retirée. **Enregistrer les modifications** demande confirmation : tous les votes sont remis à zéro, les trophées retirés et la cérémonie repasse en brouillon. Il faut ouvrir le nouveau vote et tous les votants doivent recommencer. Ce comportement s'applique aussi à une modification du titre seul.
- **Supprimer** demande confirmation puis efface la cérémonie, tous ses bulletins (anciens tours compris), résultats et trophées. Les badges et points des matchs restent indépendants.

Une ancienne page de vote ou un ancien formulaire admin ne peut pas écraser une nouvelle configuration : le serveur contrôle la révision. La remise à zéro change le tour de vote ; les bulletins du précédent tour sont exclus du compteur, du calcul et de l'affichage. Ils restent techniquement stockés jusqu'à leur remplacement par un nouveau bulletin du même votant ou à la suppression complète de la cérémonie.

Si une cérémonie créée avec 1.4.0 possède déjà des bulletins contenant deux actions du même joueur, sa réouverture les invalide et permet aux personnes concernées de revoter. Si elle est encore ouverte, utiliser **Annuler la cérémonie**, puis **Rouvrir le vote**, ou la modifier pour repartir de zéro. Ne pas clôturer un tel ancien vote avant cette correction.

## Nouveaux seuils des badges

| Badge | Condition (par saison, sauf Cap des 50) |
|---|---|
| Buteur | Bronze 5 buts, argent 15, or 25 |
| Passeur | Bronze 5 passes, argent 15, or 25 |
| Couteau suisse | Bronze 3 buts **et** 3 passes, argent 8 **et** 8, or 15 **et** 15. Aucun carton ne contribue au badge. |
| Centurion | 30 points |
| Cap des 50 | 50 points cumulés sur **toutes les saisons**, hors matchs de test et cérémonies |
| En feu | Top 3 sur 3 matchs joués consécutifs |
| Révélation | Moyenne des matchs suivants supérieure d'au moins 40 % à celle des 3 premiers, à partir du quatrième match et avec une moyenne initiale non nulle |
| Podium Master | 5 premières places |

La carte Révélation de l'accueil utilise également les trois premiers matchs comme référence. Les autres badges sont inchangés. Seul **Cap des 50** additionne les saisons ; les meilleurs paliers valides des anciennes saisons restent conservés pour les autres badges. Une correction ou suppression de match peut abaisser ou retirer un badge, y compris Cap des 50 si le total repasse sous 50. Le profil présente désormais 13 catégories de badges.

## Installer

Mettre à jour **le serveur avant les applications**. L'archive `build/chc-backend-update-1.4.1.tar.gz` contient les sources, pages publiques et fichiers npm, sans secrets ni dépendances installées. La transférer sur le VPS dans `/tmp/chc-backend-update-1.4.1.tar.gz`, puis :

```bash
cd /opt/hockey-club-server &&
sudo tar -czf /tmp/chc-server-before-1.4.1.tar.gz \
  src public dist package.json package-lock.json &&
sudo chown hockey:hockey package.json package-lock.json &&
sudo -u hockey tar -xzf /tmp/chc-backend-update-1.4.1.tar.gz \
  -C /opt/hockey-club-server &&
sudo -u hockey npm ci &&
sudo -u hockey npm run build &&
sudo systemctl restart hockey-club-server
```

Les dossiers `src` et `public` doivent appartenir à `hockey`, comme lors des installations précédentes. Le service ne redémarre que si les étapes précédentes réussissent. Aucun changement de Node, npm ou `.env` n'est requis.

```bash
sudo systemctl status hockey-club-server --no-pager
sudo journalctl -u hockey-club-server -n 40 --no-pager
```

Les règles Firestore sont les mêmes que dans 1.4.0. Si elles n'ont pas encore été installées, lancer depuis la racine du dépôt sur le PC :

```powershell
firebase deploy --only firestore:rules --project chc-mvp
```

Publier ensuite les changements Git pour redéployer Vercel et distribuer une nouvelle application Android signée suivant les guides existants. Vérifier **1.4.1 (11)** dans le profil. L'APK debug généré sert aux vérifications techniques, pas à la distribution de production.

Enfin, lancer **Administration → Reconstruire les classements maintenant** une fois pour appliquer les nouveaux seuils aux matchs existants. De nouveaux badges ou paliers peuvent alors déclencher les notifications habituelles. Cette reconstruction ne change pas les résultats des cérémonies.

Le [guide d'utilisation](GUIDE_UTILISATION.md) et le tutoriel intégré décrivent ces nouveaux comportements. Aucun déploiement ni aucune modification de données de production n'est effectué par la préparation de cette version.
