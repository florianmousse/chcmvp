import nodemailer from "nodemailer";

/**
 * Gmail SMTP avec un mot de passe d'application (nécessite la validation en
 * 2 étapes activée sur le compte Gmail utilisé). Recommandé : un compte
 * Gmail dédié au club plutôt qu'un compte personnel — voir
 * DEPLOY_ORACLE_VPS.md ou le message de Claude pour la marche à suivre
 * (nom, adresse, photo).
 */
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_APP_PASSWORD,
  },
});

const CLUB_NAME = process.env.CLUB_NAME ?? "Châteaubourg Hockey Club";
const CLUB_LOGO_URL = process.env.CLUB_LOGO_URL; // optionnel

function logoHtml(): string {
  return CLUB_LOGO_URL
    ? `<img src="${CLUB_LOGO_URL}" alt="${CLUB_NAME}" style="max-height:64px;margin-bottom:16px;" />`
    : `<h2 style="margin:0 0 16px;color:#1B5E20;">${CLUB_NAME}</h2>`;
}

function wrapHtml(bodyHtml: string): string {
  return `
    <div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;padding:24px;color:#1a1a1a;">
      ${logoHtml()}
      ${bodyHtml}
      <hr style="border:none;border-top:1px solid #eee;margin:24px 0;" />
      <p style="font-size:12px;color:#999;">${CLUB_NAME}</p>
    </div>
  `;
}

function isSmtpConfigured(): boolean {
  return !!process.env.SMTP_USER && !!process.env.SMTP_APP_PASSWORD;
}

function button(href: string, label: string): string {
  return `
    <p style="text-align:center;margin:32px 0;">
      <a href="${href}"
         style="background:#1B5E20;color:#ffffff;padding:12px 24px;border-radius:6px;text-decoration:none;font-weight:bold;">
        ${label}
      </a>
    </p>
    <p style="font-size:13px;color:#666;">
      Si le bouton ne fonctionne pas, copie ce lien dans ton navigateur :<br />
      <a href="${href}">${href}</a>
    </p>
  `;
}

export async function sendInviteEmail({
  to,
  firstName,
  resetLink,
}: {
  to: string;
  firstName: string;
  resetLink: string;
}): Promise<void> {
  if (!isSmtpConfigured()) {
    console.warn(
      `SMTP non configuré (.env) — e-mail d'invitation pour ${to} non envoyé. Lien : ${resetLink}`,
    );
    return;
  }

  await transporter.sendMail({
    from: `"${CLUB_NAME}" <${process.env.SMTP_USER}>`,
    to,
    subject: `${CLUB_NAME} — active ton compte`,
    text:
      `Bonjour ${firstName},\n\n` +
      `Un compte t'a été créé sur l'application du ${CLUB_NAME}. ` +
      `Clique sur ce lien pour choisir ton mot de passe :\n${resetLink}\n\n` +
      `À bientôt !\n${CLUB_NAME}`,
    html: wrapHtml(`
      <p>Bonjour ${firstName},</p>
      <p>Un compte t'a été créé sur l'application du <strong>${CLUB_NAME}</strong>.</p>
      ${button(resetLink, "Définir mon mot de passe")}
    `),
  });
}

/**
 * "Mot de passe oublié" — appelée depuis une route PUBLIQUE (voir
 * routes/auth.ts), puisque quelqu'un qui a oublié son mot de passe n'est
 * par définition pas connecté et ne peut fournir aucun token.
 */
export async function sendPasswordResetEmail({
  to,
  resetLink,
}: {
  to: string;
  resetLink: string;
}): Promise<void> {
  if (!isSmtpConfigured()) {
    console.warn(
      `SMTP non configuré (.env) — e-mail de réinitialisation pour ${to} non envoyé. Lien : ${resetLink}`,
    );
    return;
  }

  await transporter.sendMail({
    from: `"${CLUB_NAME}" <${process.env.SMTP_USER}>`,
    to,
    subject: `${CLUB_NAME} — réinitialise ton mot de passe`,
    text:
      `Bonjour,\n\n` +
      `Clique sur ce lien pour choisir un nouveau mot de passe :\n${resetLink}\n\n` +
      `Si tu n'es pas à l'origine de cette demande, ignore simplement cet e-mail.\n\n${CLUB_NAME}`,
    html: wrapHtml(`
      <p>Bonjour,</p>
      <p>Tu as demandé à réinitialiser ton mot de passe sur l'application du <strong>${CLUB_NAME}</strong>.</p>
      ${button(resetLink, "Réinitialiser mon mot de passe")}
      <p style="font-size:13px;color:#666;">Si tu n'es pas à l'origine de cette demande, ignore simplement cet e-mail — rien ne sera changé.</p>
    `),
  });
}
