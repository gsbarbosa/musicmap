/**
 * Deploy: firebase deploy --only functions
 * Config e-mail (Resend): firebase functions:config:set resend.key="re_xxx"
 * Domínio "from" deve estar verificado no Resend.
 */
const functions = require('firebase-functions/v1');
const {onRequest} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();

const SHARE_BRAND = 'Palace Pulse';

/**
 * Hosting + Cloud Functions 2nd gen: o path público (/share/artist/:id) muitas vezes
 * não vem em req.path (fica '/', ou só o sufixo interno). Varre URL, originalUrl e
 * todos os headers — inclusive x-firebase-hosting-path.
 */
function extractProfileIdFromRequest(req) {
  const patterns = [
    /\/artistShare\/share\/artist\/([^/?#]+)/,
    /\/shareArtistPublic\/share\/artist\/([^/?#]+)/,
    /\/share\/artist\/([^/?#]+)/,
    /share\/artist\/([^/?#]+)/,
    // Acesso direto ao hostname Cloud Run (*.run.app): path costuma ser /artist/:id
    /\/artist\/([^/?#]+)/,
  ];

  const tryString = (raw) => {
    if (raw == null) return null;
    const s = String(raw).trim();
    if (!s) return null;
    let t = s.split('?')[0].split('#')[0];
    try {
      t = decodeURIComponent(t);
    } catch (_) {
      /* ignore */
    }
    for (const re of patterns) {
      const m = t.match(re);
      if (m && m[1]) return m[1];
    }
    return null;
  };

  const pushAll = (arr, val) => {
    if (val == null) return;
    if (Array.isArray(val)) {
      val.forEach((v) => pushAll(arr, v));
      return;
    }
    arr.push(String(val));
  };

  const buckets = [];
  pushAll(buckets, req.path);
  pushAll(buckets, req.url);
  pushAll(buckets, req.originalUrl);

  if (typeof req.get === 'function') {
    const headerNames = [
      'x-forwarded-uri',
      'x-forwarded-url',
      'x-original-url',
      'x-firebase-hosting-path',
      'x-envoy-original-path',
      'forwarded',
    ];
    for (const name of headerNames) {
      pushAll(buckets, req.get(name));
    }
  }

  if (req.headers && typeof req.headers === 'object') {
    for (const key of Object.keys(req.headers)) {
      pushAll(buckets, req.headers[key]);
    }
  }

  if (req.rawRequest) {
    pushAll(buckets, req.rawRequest.url);
    const rh = req.rawRequest.headers;
    if (rh && typeof rh === 'object') {
      for (const key of Object.keys(rh)) {
        pushAll(buckets, rh[key]);
      }
    }
  }

  const q = req.query && (req.query.id || req.query.profileId);
  if (q && typeof q === 'string' && q.length > 0 && q.length < 129) return q;

  const rawUrl = String(req.originalUrl || req.url || '');
  const qMark = rawUrl.indexOf('?');
  if (qMark !== -1) {
    try {
      const params = new URLSearchParams(rawUrl.slice(qMark + 1));
      const fromQs = params.get('id') || params.get('profileId');
      if (fromQs && fromQs.length > 0 && fromQs.length < 129) return fromQs;
    } catch (_) {
      /* ignore */
    }
  }

  for (const b of buckets) {
    const id = tryString(b);
    if (id) return id;
  }

  const pathOnly = String(req.path || '');
  const segs = pathOnly.split('/').filter(Boolean);
  const ai = segs.indexOf('artist');
  if (ai > 0 && segs[ai - 1] === 'share' && segs[ai + 1]) {
    return segs[ai + 1];
  }
  if (segs.length >= 2 && segs[0] === 'artist' && segs[1]) {
    return segs[1];
  }

  return null;
}

/**
 * Links públicos devem apontar para o domínio do Hosting (SPA), não para *.run.app.
 * Evita meta refresh para URL da CF (404) e OG com URL errada.
 */
function canonicalSiteOrigin(req) {
  const host = (req.get('host') || '').toLowerCase();
  const internalHost =
    host.endsWith('.run.app') ||
    host.includes('.cloudfunctions.net') ||
    host === '127.0.0.1' ||
    host.startsWith('localhost');
  if (internalHost) {
    const fromEnv = process.env.PUBLIC_SITE_ORIGIN || process.env.SITE_ORIGIN;
    if (fromEnv && String(fromEnv).trim()) {
      return String(fromEnv).trim().replace(/\/$/, '');
    }
    const projectId =
      (admin.app() && admin.app().options && admin.app().options.projectId) ||
      process.env.GCLOUD_PROJECT ||
      process.env.GCP_PROJECT ||
      '';
    if (projectId) {
      return `https://${projectId}.web.app`;
    }
  }
  const proto = req.get('x-forwarded-proto') || 'https';
  return `${proto}://${req.get('host') || 'localhost'}`;
}

function escHtml(s) {
  if (s == null || s === undefined) return '';
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Aceita convite de projeto: grava user_profile_access e profile_members e incrementa uses.
 */
exports.acceptInvite = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Faça login para aceitar o convite');
  }
  const token = data && data.token;
  if (!token || typeof token !== 'string' || token.length < 8 || token.length > 64) {
    throw new functions.https.HttpsError('invalid-argument', 'Código de convite inválido');
  }
  const uid = context.auth.uid;
  const db = admin.database();
  const invRef = db.ref(`invite_by_code/${token}`);
  const snap = await invRef.once('value');
  if (!snap.exists()) {
    throw new functions.https.HttpsError('not-found', 'Convite não encontrado');
  }
  const inv = snap.val();
  const profileId = inv.profileId;
  const role = inv.role === 'admin' || inv.role === 'viewer' ? inv.role : 'editor';
  const maxUses = typeof inv.maxUses === 'number' ? inv.maxUses : 30;
  let uses = typeof inv.uses === 'number' ? inv.uses : 0;
  const expiresAt = inv.expiresAt;
  if (!profileId || typeof profileId !== 'string') {
    throw new functions.https.HttpsError('failed-precondition', 'Convite corrompido');
  }
  if (expiresAt != null && typeof expiresAt === 'number' && Date.now() > expiresAt) {
    throw new functions.https.HttpsError('failed-precondition', 'Este convite expirou');
  }
  if (uses >= maxUses) {
    throw new functions.https.HttpsError('resource-exhausted', 'Este convite atingiu o limite de usos');
  }
  const profSnap = await db.ref(`profiles/${profileId}`).once('value');
  if (!profSnap.exists()) {
    throw new functions.https.HttpsError('not-found', 'Projeto não existe mais');
  }
  const ownerId = profSnap.val().ownerUserId;
  if (ownerId === uid) {
    return { ok: true, profileId, alreadyOwner: true };
  }
  const accessSnap = await db.ref(`user_profile_access/${uid}/${profileId}`).once('value');
  if (accessSnap.exists()) {
    return { ok: true, profileId, alreadyMember: true };
  }
  const joinedAt = new Date().toISOString();
  const updates = {};
  updates[`user_profile_access/${uid}/${profileId}`] = { role, joinedAt };
  updates[`profile_members/${profileId}/${uid}`] = { role, joinedAt };
  updates[`invite_by_code/${token}/uses`] = uses + 1;
  await db.ref().update(updates);
  return { ok: true, profileId, role };
});

/** Incrementa stats/profile_views/{profileId} */
exports.recordProfileView = functions.https.onCall(async (data) => {
  const profileId = data.profileId;
  if (!profileId || typeof profileId !== 'string' || profileId.length > 128) {
    throw new functions.https.HttpsError('invalid-argument', 'profileId inválido');
  }
  const snap = await admin.database().ref(`profiles/${profileId}`).once('value');
  if (!snap.exists()) {
    throw new functions.https.HttpsError('not-found', 'Perfil não encontrado');
  }
  const p = snap.val();
  if (p.status !== 'active' || p.publicProfile === false) {
    return { ok: false, reason: 'not_public' };
  }
  const ref = admin.database().ref(`stats/profile_views/${profileId}`);
  await ref.transaction((current) => (current || 0) + 1);
  return { ok: true };
});

/**
 * HTML com Open Graph para WhatsApp/Instagram.
 * Hosting rewrite: /share/artist/** → shareArtistPublic (firebase.json)
 *
 * Nome **diferente** de `artistShare`: Firebase não permite upgrade 1st Gen → 2nd Gen no mesmo nome.
 * Depois do deploy OK: `firebase functions:delete artistShare --region us-central1` (remove a 1st Gen órfã).
 *
 * v2 + invoker: 'public' — link público precisa de invocação anônima (evita 403 no GCP).
 */
exports.shareArtistPublic = onRequest(
  {
    region: 'us-central1',
    invoker: 'public',
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (req, res) => {
    res.set('Cache-Control', 'public, max-age=120, s-maxage=300');
    const siteOrigin = canonicalSiteOrigin(req);

    const profileId = extractProfileIdFromRequest(req);
    if (!profileId) {
      res.status(404).send('<!DOCTYPE html><html><body>Link inválido</body></html>');
      return;
    }

    const snap = await admin.database().ref(`profiles/${profileId}`).once('value');
    if (!snap.exists()) {
      res.status(404).send('<!DOCTYPE html><html><body>Perfil não encontrado</body></html>');
      return;
    }
    const p = snap.val();
    if (p.status !== 'active' || p.publicProfile === false) {
      res.status(404).send('<!DOCTYPE html><html><body>Perfil indisponível</body></html>');
      return;
    }

    const title = escHtml(p.artistName || SHARE_BRAND);
    const city = p.city || '';
    const state = p.state || '';
    const desc = `${city}${city && state ? ' – ' : ''}${state} · ${p.genre || 'Artista'} · ${SHARE_BRAND}`;
    const photo = p.photoUrl && String(p.photoUrl).trim() ? String(p.photoUrl).trim() : '';
    const shareUrl = `${siteOrigin}/share/artist/${profileId}`;
    const appUrl = `${siteOrigin}/artist/${profileId}`;

    const ogImageTags = photo
      ? `<meta property="og:image" content="${escHtml(photo)}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:image" content="${escHtml(photo)}">`
      : `<meta name="twitter:card" content="summary">`;

    const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title} · ${SHARE_BRAND}</title>
<meta name="description" content="${escHtml(desc)}">
<meta property="og:title" content="${title} · ${SHARE_BRAND}">
<meta property="og:description" content="${escHtml(desc)}">
${ogImageTags}
<meta property="og:url" content="${escHtml(shareUrl)}">
<meta property="og:type" content="profile">
<meta name="twitter:title" content="${title}">
<meta name="twitter:description" content="${escHtml(desc)}">
<meta http-equiv="refresh" content="0;url=${escHtml(appUrl)}">
</head>
<body>
<p>Redirecionando para <a href="${escHtml(appUrl)}">${title}</a>…</p>
</body>
</html>`;
    res.set('Content-Type', 'text/html; charset=utf-8');
    res.status(200).send(html);
  },
);

/** E-mail de boas-vindas (Resend). Config: firebase functions:config:set resend.key="re_xxx" */
exports.onAuthUserCreate = functions.auth.user().onCreate(async (user) => {
  const resendKey =
    process.env.RESEND_API_KEY ||
    (functions.config().resend && functions.config().resend.key);
  if (!resendKey) {
    console.log('Welcome email: defina RESEND_API_KEY ou functions.config().resend.key');
    return;
  }
  const email = user.email;
  if (!email) return;

  const from =
    process.env.RESEND_FROM || 'Music Map <onboarding@resend.dev>';

  try {
    const r = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from,
        to: [email],
        subject: 'Bem-vindo ao Music Map',
        html:
          '<p>Olá!</p>' +
          '<p>Você entrou na <strong>cena fundadora</strong> do Music Map.</p>' +
          '<p>Complete seu perfil para aparecer no mapa e use o link público para compartilhar nas redes.</p>' +
          '<p>— Equipe Music Map</p>',
      }),
    });
    if (!r.ok) {
      const t = await r.text();
      console.error('Resend error', r.status, t);
    }
  } catch (e) {
    console.error('Welcome email failed', e);
  }
});
