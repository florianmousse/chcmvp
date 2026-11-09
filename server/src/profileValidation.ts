/** Validate the editable profile boundary before writing through Admin SDK. */
export function validateProfilePatch(data: Record<string, unknown>): void {
  function invalid(): never {
    throw Object.assign(new Error('Profil invalide.'), { status: 400 });
  }
  for (const key of ['firstName', 'lastName', 'team']) {
    const value = data[key];
    if (key in data && (typeof value !== 'string' || !value.trim() || value.length > 120)) invalid();
  }
  const number = data.jerseyNumber;
  if (number != null && (typeof number !== 'number' || !Number.isSafeInteger(number) || number < 0 || number > 999)) invalid();
  const photo = data.photoUrl;
  if (photo != null) {
    if (typeof photo !== 'string' || photo.length > 2048) invalid();
    try {
      const url = new URL(photo);
      if (url.protocol !== 'https:' || url.username || url.password) invalid();
    } catch { invalid(); }
  }
}
