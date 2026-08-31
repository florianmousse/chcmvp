# Déployer l'app sur le Google Play Store

## 0. Prérequis

- Un compte **Google Play Console** (console.play.google.com) — **25$ à payer une seule
  fois**, pas un abonnement. Compte Google normal + vérification d'identité (peut prendre
  quelques jours la première fois, à anticiper).
- Une **politique de confidentialité** publiée quelque part avec une URL publique —
  **obligatoire** pour publier, même pour une app de club. Comme l'app collecte des
  données personnelles (nom, e-mail, votes) via Firebase, ce n'est pas juste une
  formalité : Google vérifie que cette page existe et correspond à ce que déclare le
  formulaire "Sécurité des données" (étape 6). Une simple page web (même une seule page
  markdown/HTML hébergée n'importe où, y compris sur ton VPS) suffit — dis-moi si tu veux
  que je t'en rédige une.

## 1. Générer la clé de signature ("upload key")

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
`keytool` vient avec le JDK — si la commande n'est pas reconnue, cherche-le dans
`C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe` (ou équivalent selon où est
installé Android Studio) et utilise le chemin complet.

Répond aux questions (nom, organisation, etc. — peu importe ce que tu mets, ça n'apparaît
nulle part publiquement). Choisis un mot de passe solide et **note-le quelque part de
sûr** : ce fichier `.jks` et ce mot de passe sont irremplaçables — si tu les perds, tu ne
pourras plus jamais publier de mise à jour de l'app sous le même identifiant, il faudrait
recréer une app entièrement nouvelle sur le Play Store.

**Ne commite jamais ce fichier dans git.** Garde-le en dehors du dossier du projet, par
exemple `C:\Users\<TON_USER>\keystores\upload-keystore.jks`.

## 2. Configurer la signature dans le projet

Crée `android/key.properties` (à la racine du dossier `android/`, **jamais commité** —
vérifie qu'il est bien dans `.gitignore`, ajoute la ligne `key.properties` sinon) :
```properties
storePassword=<le mot de passe que tu as choisi>
keyPassword=<le même, en général>
keyAlias=upload
storeFile=<CHEMIN_ABSOLU_VERS>/upload-keystore.jks
```

Dans `android/app/build.gradle.kts`, tout en haut du fichier, ajoute :
```kotlin
import java.util.Properties
import java.io.FileInputStream
```

Puis à l'intérieur du bloc `android { ... }` (à côté de `compileOptions` que tu as déjà) :
```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

## 3. Vérifier l'identité de l'app

Dans `android/app/build.gradle.kts`, repère `applicationId` (probablement
`com.example.hockey_club_app` par défaut) — **change-le maintenant si besoin**, avant la
première publication : impossible à modifier après coup sans republier une app entièrement
différente. Une convention courante : `fr.chateaubourghockeyclub.app` ou similaire (à toi
de choisir, doit être unique sur tout le Play Store).

## 4. Construire le fichier à envoyer

```powershell
flutter build appbundle --release
```
Génère `build/app/outputs/bundle/release/app-release.aab` — c'est ce fichier `.aab`
(Android App Bundle, pas un `.apk`) qu'on envoie au Play Store.

## 5. Créer l'app sur Play Console

1. **Créer l'application** : nom, langue par défaut (français), type (application),
   gratuite ou payante (gratuite dans ton cas).
2. **Play App Signing** : Google te proposera d'activer ça au premier envoi — **accepte**,
   c'est activé par défaut aujourd'hui et recommandé. Ça veut dire que Google **regénère
   sa propre clé de signature** pour ce que les utilisateurs installent réellement ; ta
   clé "upload" (étape 1) ne sert qu'à authentifier tes envois vers Play Console, pas à
   signer ce qui est distribué. **Point important pour Google Sign-In** : le SHA-1 à
   ajouter à Firebase pour que Google Sign-In fonctionne en production n'est donc **pas**
   celui de ton `upload-keystore.jks`, mais celui que Google Play Console affiche après
   ton premier envoi, dans **Configuration > Intégrité de l'application > Certificat de
   signature de l'app** (disponible seulement après le premier upload).
3. **Fiche Play Store** : description courte (80 caractères) et longue, catégorie
   (Sport), icône 512×512, image de présentation 1024×500, et **captures d'écran**
   (minimum 2, format téléphone) — prends-les directement sur ton téléphone une fois
   l'app installée.
4. **Envoyer le `.aab`** : Production > Créer une release (ou Test interne, voir étape 7)
   > glisse le fichier `app-release.aab`.

## 6. Formulaires obligatoires

- **Sécurité des données** (Data safety) : déclare quelles données sont collectées
  (nom, e-mail, statistiques de vote) et pourquoi. Doit correspondre à ta politique de
  confidentialité (étape 0).
- **Classification du contenu** : questionnaire standard, une app de club sportif sans
  contenu sensible se classe "Tout public" sans souci.
- **Coordonnées** : e-mail de contact visible publiquement sur la fiche.

## 7. Tester avant la mise en production (fortement recommandé)

Plutôt que d'aller direct en production, utilise d'abord une piste de **test interne** :
Play Console > Tester > Test interne > ajoute les e-mails Google des personnes qui
doivent tester (toi, quelques membres du club) > envoie le même `.aab`. Pas de revue
Google nécessaire, disponible en quelques minutes, permet de repérer des soucis avant
que ce soit public.

## 8. Publier en production

Une fois satisfait du test interne, promeus la même release vers Production (ou envoie-la
directement en Production si tu sautes le test interne). **La première soumission est
examinée par Google et peut prendre plusieurs jours** (les mises à jour suivantes sont
généralement plus rapides, souvent quelques heures). Une fois approuvée, l'app est
disponible publiquement sur le Play Store.

## 9. Mettre à jour l'app plus tard

Dans `pubspec.yaml`, la ligne `version:` (ex: `1.0.0+1`) — incrémente le nombre après le
`+` (le "version code") à **chaque nouvel envoi**, Google le refuse sinon. Le nombre avant
le `+` (le "version name", ex: `1.0.1`) est ce que voient les utilisateurs, à toi de le
faire évoluer selon tes conventions. Puis :
```powershell
flutter build appbundle --release
```
et renvoie le nouveau `.aab` dans Play Console > Production > Créer une release.
