import { readFile, writeFile } from "node:fs/promises";

const root = new URL("../", import.meta.url);
const config = JSON.parse(
  await readFile(new URL("web/legal-config.json", root), "utf8"),
);
const escape = (value) =>
  String(value).replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        c
      ],
  );
for (const key of ["publisher", "address", "director", "email", "updated"]) {
  if (!config[key]?.trim())
    throw new Error(`Informations légales manquantes : ${key}`);
}
const c = Object.fromEntries(
  Object.entries(config).map(([key, value]) => [key, escape(value)]),
);
const contact = `<a href="mailto:${c.email}">${c.email}</a>`;
const pages = [
  {
    file: "mentions-legales.html",
    title: "Mentions légales",
    intro:
      "Les informations sur l'éditeur et les services qui font fonctionner CHC MVP.",
    content: `<h2>Éditeur</h2><p><strong>${c.publisher}</strong><br>${c.address}<br>Contact : ${contact}</p>
      <h2>Responsable de publication</h2><p>${c.director}.</p>
      <h2>Hébergement de la version web</h2><p>Vercel Inc., 440 N Barranca Ave #4133, Covina, CA 91723, États-Unis.<br>Informations et contact : <a href="https://vercel.com/legal/terms">vercel.com/legal/terms</a> et <a href="https://vercel.com/help">assistance Vercel</a>.</p>
      <p>Les comptes et les données sportives utilisent Google Firebase. Les traitements de résultats et l'envoi d'e-mails sont exécutés sur le serveur administré par le club. Les prestataires et leurs rôles sont détaillés dans la <a href="/confidentialite.html">politique de confidentialité</a>.</p>
      <h2>Objet du service</h2><p>CHC MVP est l'espace des membres du club pour consulter les matchs, voter pour un top 3 et suivre les classements. L'accès aux données du club nécessite un compte autorisé.</p>
      <h2>Propriété intellectuelle</h2><p>Le nom, le logo du club et les contenus restent la propriété de leurs titulaires respectifs. Leur présence dans l'application n'autorise pas leur réutilisation sans accord. Les logos des équipes adverses appartiennent à leurs titulaires.</p>
      <h2>Nous contacter</h2><p>Pour signaler une erreur ou un problème d'accès : ${contact}. Les règles de participation figurent dans les <a href="/conditions-utilisation.html">conditions d'utilisation</a>.</p>`,
  },
  {
    file: "confidentialite.html",
    title: "Politique de confidentialité",
    intro:
      "Tes données servent à faire vivre les matchs et les votes du club. Elles ne sont pas vendues et cette version n'intègre ni publicité ni outil de mesure d'audience.",
    content: `<h2>Qui est responsable ?</h2><p>${c.publisher}, ${c.address}, est responsable du traitement. Pour toute question ou demande relative à tes données, écris à ${contact} (contact : ${c.director}).</p>
      <h2>Quelles données sont utilisées ?</h2><p>Un administrateur crée ta fiche à partir des informations fournies au club : nom, prénom, équipe, numéro de maillot et éventuellement photo. L’adresse e-mail est facultative pour une fiche joueur ; elle est nécessaire pour créer un accès personnel. Firebase Authentication gère tes identifiants de connexion. Avec Google, Firebase reçoit notamment l'identifiant du compte, l'adresse e-mail et les informations de profil autorisées.</p>
      <p>L'application enregistre la présence aux matchs, les trois choix de chaque vote, son auteur et sa date, ainsi que les résultats, points, classements, badges, buts, passes et cartons saisis par les administrateurs. Le thème choisi est enregistré dans le navigateur. Les services techniques reçoivent également des données de connexion, dont l'adresse IP.</p>
      <h2>Pourquoi et sur quelle base ?</h2><p>L'accès à l'espace réservé et l'organisation des votes reposent sur la fourniture du service sportif demandé par le membre dans le cadre de son adhésion. La sécurité, la prévention des votes multiples et le suivi sportif interne répondent à l'intérêt légitime du club. Ces bases doivent être appréciées au regard de la situation du membre, notamment s'il est mineur.</p>
      <p>Une fiche sans e-mail permet de figurer sur les feuilles de match et de recevoir des votes, sans créer de compte de connexion. L’ajout ultérieur d’une adresse e-mail permet au club d’inviter le joueur en conservant son historique. L'e-mail et l'identité du membre sont nécessaires pour contrôler l'accès. Sans compte autorisé, le vote n'est pas possible. La photo et la connexion Google sont facultatives ; la connexion par e-mail et mot de passe reste disponible.</p>
      <h2>Qui peut voir quoi ?</h2><p>Les membres actifs peuvent consulter les fiches membres (y compris les e-mails actuellement présents dans ces fiches), équipes, présences, statistiques et classements. Les administrateurs gèrent les membres et les matchs.</p>
      <p class="notice"><strong>Les votes sont confidentiels entre joueurs, mais pas anonymes techniquement.</strong> Chaque vote reste lié à l'identifiant de son auteur. Les règles de la base empêchent un membre de lire le bulletin d'un autre ; les personnes habilitées à administrer le backend peuvent techniquement y accéder. Les résultats affichés sont agrégés.</p>
      <h2>Prestataires et transferts</h2><p>Vercel distribue les fichiers du site et traite les requêtes techniques. Google Firebase fournit l'authentification et la base Firestore ; Google peut aussi servir les composants de connexion et certaines polices de secours. Le VPS du club (infrastructure Oracle Cloud selon la configuration du projet) exécute les traitements serveur ; le service SMTP configuré par le club transmet les invitations et réinitialisations de mot de passe.</p>
      <p>Certains prestataires interviennent hors de l'Union européenne. Leurs conditions contractuelles décrivent les garanties applicables, notamment les clauses contractuelles types lorsqu'elles sont utilisées. Tu peux demander au club les informations sur les régions d'hébergement et les garanties de transfert effectivement retenues. Voir les informations de <a href="https://firebase.google.com/support/privacy">Firebase</a> et le <a href="https://vercel.com/legal/dpa">contrat de traitement des données Vercel</a>.</p>
      <h2>Conservation</h2><p>La fiche joueur est conservée pendant sa participation au suivi sportif du club, avec ou sans compte de connexion. Les bulletins et historiques nominatifs restent en base tant qu'ils sont nécessaires à la vérification des résultats et au suivi des saisons du club. Une demande de suppression déclenche un examen par l'administrateur des données associées, des éventuelles obligations de conservation et des historiques concernés. L'application n'effectue pas de purge automatique.</p>
      <p>La déconnexion retire la session locale sans supprimer le compte. Le thème reste mémorisé jusqu'à son changement ou à l'effacement des données du site. Les journaux techniques suivent les durées configurées auprès des prestataires ; le club peut les préciser sur demande.</p>
      <h2>Tes droits</h2><p>Tu peux demander l'accès, la rectification, l'effacement ou la limitation de tes données, et, selon la base applicable, leur portabilité ou t'opposer au traitement. Adresse ta demande à ${contact}. Une vérification d'identité proportionnée peut être nécessaire. Une réponse est en principe apportée sous un mois ; une prolongation motivée peut être annoncée dans les cas prévus par le RGPD.</p>
      <p>Tu peux également adresser une réclamation à la <a href="https://www.cnil.fr/fr/adresser-une-plainte">CNIL</a>. Pour commencer une demande, consulte <a href="/supprimer-compte.html">Mes données et suppression du compte</a>.</p>
      <h2>Classements et mineurs</h2><p>Le barème du match transforme automatiquement les votes en points et en classements sportifs. Ce calcul ne décide pas automatiquement de l'accès à un droit ni d'une sanction. Pour un membre mineur, le club et son représentant légal peuvent accompagner l'utilisation et l'exercice des droits.</p>
      <h2>Stockage sur ton appareil</h2><p>La <a href="/cookies.html">page cookies et stockage local</a> décrit les mécanismes nécessaires au service. Les notifications push ne sont pas activées dans cette version web.</p>`,
  },
  {
    file: "cookies.html",
    title: "Cookies et stockage local",
    intro:
      "Cette version utilise uniquement le stockage nécessaire à la connexion, à la sécurité et à tes préférences d'affichage.",
    content: `<h2>Connexion</h2><p>Firebase Authentication conserve la session dans le stockage du navigateur (notamment IndexedDB ou stockage local selon le navigateur) pour te permettre de rester connecté. Ces données sont retirées à la déconnexion ou lorsque tu effaces les données du site. Sur un appareil partagé, pense à te déconnecter.</p>
      <h2>Préférence de thème</h2><p>La préférence « Système », « Clair » ou « Sombre » est enregistrée localement sous la clé <code>flutter.theme_mode</code> via SharedPreferences. Elle reste jusqu'à son remplacement ou à l'effacement des données du site.</p>
      <h2>Fichiers techniques</h2><p>Le navigateur peut mettre en cache les fichiers, images et polices nécessaires à l'affichage. La version livrée n'enregistre pas de service worker de fonctionnement hors ligne et ne propose pas de vote hors connexion. La connexion Google peut ouvrir une fenêtre du fournisseur à ta demande.</p>
      <h2>Pourquoi aucun bandeau « Accepter / Refuser » ?</h2><p>Aucun traceur publicitaire ni outil de mesure d'audience n'est intégré. Les mécanismes strictement nécessaires au service demandé et à sa personnalisation attendue ne nécessitent pas de consentement préalable, selon la <a href="https://www.cnil.fr/fr/cookies-et-autres-traceurs/que-dit-la-loi">CNIL</a>. Un bandeau de consentement serait à ajouter avant tout futur traceur non essentiel.</p>
      <h2>Effacer les données locales</h2><p>Déconnecte-toi depuis Profil. Dans les réglages de ton navigateur, ouvre les données de sites, sélectionne ce site puis efface ses données. Cela réinitialise la session et les préférences sans supprimer ton compte ni tes votes conservés par le club. Consulte <a href="/supprimer-compte.html">Mes données</a> pour demander leur suppression.</p>`,
  },
  {
    file: "conditions-utilisation.html",
    title: "Conditions d'utilisation",
    intro:
      "Un espace réservé aux membres, pour valoriser les performances avec respect et équité.",
    content: `<h2>Accès</h2><p>Le compte est créé ou autorisé par un administrateur du ${c.publisher}. Il est personnel. Ne partage pas tes identifiants et signale tout accès suspect à ${contact}.</p>
      <h2>Voter pour un match</h2><p>Un membre actif figurant sur la feuille de présence peut voter une fois pendant la période ouverte. Il choisit trois joueurs distincts présents au match, dans l'ordre. L'auto-vote dépend du réglage choisi par l'administrateur. Un vote validé est définitif.</p>
      <p>Le barème est configurable pour chaque match ; sa valeur par défaut est de 5 points pour le premier, 3 pour le deuxième et 1 pour le troisième. Les classements sont recalculés par le serveur à la clôture. Un délai d'actualisation est possible.</p>
      <h2>Respect des membres</h2><p>Vote de bonne foi, respecte la confidentialité des informations du club et n'utilise pas les données des autres membres pour une autre finalité. Les classements sont un outil sportif et convivial ; ils ne justifient aucun comportement discriminatoire ou dénigrant.</p>
      <h2>Disponibilité et erreurs</h2><p>Une connexion Internet est nécessaire. Si une validation échoue, l'application affiche une erreur ; vérifie l'état du vote avant de réessayer. En cas d'erreur de présence, de résultat ou de profil, contacte un administrateur. Le service peut être interrompu pour maintenance.</p>
      <h2>Compte et données</h2><p>Le club peut désactiver l'accès d'un membre qui quitte le club ou utilise le service abusivement. Tu peux demander la suppression de tes données selon la <a href="/confidentialite.html">politique de confidentialité</a>. Toute question peut être adressée au club pour rechercher une solution amiable.</p>`,
  },
  {
    file: "supprimer-compte.html",
    title: "Mes données et mon compte",
    intro:
      "Demande une copie, une correction ou la suppression de tes données au club.",
    content: `<h2>Faire une demande</h2><p>Écris depuis l'adresse associée à ton compte à ${contact}, en indiquant ton nom et l'objet de ta demande. Si ta fiche n’a pas d’adresse e-mail ou si tu n'as plus accès à cette adresse, explique-le ; le club pourra vérifier ton identité autrement. Ne transmets jamais ton mot de passe.</p>
      <p><a class="button" href="mailto:${c.email}?subject=CHC%20MVP%20%E2%80%94%20Demande%20de%20suppression%20de%20compte">Demander la suppression</a></p>
      <p>Si aucun logiciel de messagerie ne s'ouvre, copie l'adresse ci-dessus dans ton service de messagerie habituel. Ce bouton prépare un e-mail ; il ne l'envoie pas et ne supprime pas le compte.</p>
      <h2>Ce qui se passe ensuite</h2><p>Un administrateur traite la demande et examine la fiche membre, le compte de connexion, les bulletins, statistiques et historiques associés. La simple désactivation du compte ne supprime pas ces données. La suppression doit aussi traiter les références dans les historiques ; elle n'est pas automatisée par le bouton d'administration actuel.</p>
      <p>Le club te précisera les suppressions ou anonymisations effectuées et les éventuelles données conservées pour un motif justifié. Une réponse est en principe apportée sous un mois, avec information en cas de prolongation légale.</p>
      <h2>Effacer seulement cet appareil</h2><p>La déconnexion depuis Profil et l'effacement des données du site dans le navigateur ne suppriment pas les informations stockées par le club. Voir <a href="/cookies.html">Cookies et stockage local</a>.</p>
      <h2>Autres demandes</h2><p>Tu peux utiliser le même contact pour une copie ou une correction de tes données. Les droits et les modalités de réclamation sont décrits dans la <a href="/confidentialite.html">politique de confidentialité</a>.</p>`,
  },
];

for (const page of pages) {
  const navigation = pages
    .map(
      (p) =>
        `<a href="/${p.file}"${p.file === page.file ? ' aria-current="page"' : ""}>${p.title}</a>`,
    )
    .join("\n");
  const html = `<!DOCTYPE html>
<html lang="fr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="theme-color" content="#3261FF"><meta name="description" content="${escape(page.intro)}"><title>${page.title} - CHC MVP</title><link rel="icon" href="/logo.png"><link rel="stylesheet" href="/site.css"></head>
<body><header><a class="brand" href="/"><img src="/logo.png" alt="Logo du club">CHC MVP</a><a href="/">Retour à l'application</a></header><main class="document"><span class="eyebrow">Châteaubourg Hockey Club</span><h1>${page.title}</h1><p class="intro">${page.intro}</p>${page.content}</main><footer><p>Mis à jour le ${c.updated} · ${c.publisher}</p><nav aria-label="Informations légales">${navigation}</nav></footer></body></html>\n`;
  await writeFile(new URL(`web/${page.file}`, root), html);
}
console.log(`${pages.length} pages légales générées dans web/.`);
