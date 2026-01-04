// index.js
const admin = require('firebase-admin');
const functions = require('@google-cloud/functions-framework');
// Use native fetch when available (Node 18+), otherwise lazy-load node-fetch.
const fetch = globalThis.fetch
  ? globalThis.fetch
  : (...args) =>
      import('node-fetch').then(({ default: fetchFn }) => fetchFn(...args));
const fs = require('fs');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'tablecheckingapp-13820',
  });
}

const db = admin.firestore();
const tables = db.collection('phoneTable');

const apiKey =
    process.env.FIREBASE_WEB_API_KEY;

if (!apiKey) {
  throw new Error('FIREBASE_WEB_API_KEY is not set');
}

const adminSecret = process.env.ADMIN_SECRET;
const allowAnyOrigin = process.env.ALLOW_ANY_ORIGIN !== 'false'; // default: allow any origin by reflecting it
const cookieSecure = process.env.COOKIE_SECURE !== 'false'; // allow disabling for local HTTP only if needed

const pickOrigin = (req) => req.headers.origin || '';

const parseCookies = (cookieHeader = '') =>
  Object.fromEntries(
    cookieHeader
      .split(';')
      .map((c) => c.trim())
      .filter(Boolean)
      .map((c) => {
        const idx = c.indexOf('=');
        if (idx === -1) return [c, ''];
        return [decodeURIComponent(c.substring(0, idx)), decodeURIComponent(c.substring(idx + 1))];
      })
  );

const requireSession = async (req, res, next) => {
  const cookies = parseCookies(req.headers.cookie || '');
  const sessionCookie = cookies.session;
  if (!sessionCookie) {
    return res.status(401).json({ error: 'Not signed in' });
  }
  try {
    req.user = await admin.auth().verifySessionCookie(sessionCookie, true);
    return next();
  } catch (err) {
    console.error('Session verification failed', err);
    return res.status(401).json({ error: 'Invalid session' });
  }
};

const sameSite = process.env.COOKIE_SAMESITE || 'None'; // None is required for cross-site cookies

const buildCookie = (name, value, maxAgeSeconds) => {
  const parts = [
    `${name}=${encodeURIComponent(value || '')}`,
    'Path=/',
    'HttpOnly',
    `SameSite=${sameSite}`,
  ];
  if (cookieSecure) {
    parts.push('Secure');
  }
  if (typeof maxAgeSeconds === 'number') {
    parts.push(`Max-Age=${maxAgeSeconds}`);
  }
  return parts.join('; ');
};

const setSessionCookie = async (res, idToken) => {
  const expiresInMs = 7 * 24 * 60 * 60 * 1000; // 7 days
  const sessionCookie = await admin.auth().createSessionCookie(idToken, { expiresIn: expiresInMs });
  res.setHeader('Set-Cookie', [buildCookie('session', sessionCookie, expiresInMs / 1000)]);
};

const clearSessionCookie = (res) => {
  res.setHeader('Set-Cookie', [buildCookie('session', '', 0)]);
};

functions.http('helloHttp', async (req, res) => {
  const origin = pickOrigin(req);
  if (allowAnyOrigin && origin) {
    res.set('Access-Control-Allow-Origin', origin);
  }
  res.set('Access-Control-Allow-Credentials', 'true');
  res.set('Access-Control-Allow-Headers', 'Content-Type,x-admin-secret');
  res.set('Access-Control-Allow-Methods', 'GET,POST,PUT,OPTIONS');

  if (req.method === 'OPTIONS') return res.status(204).send('');

  // Health
  if (req.method === 'GET' && req.path === '/') {
    return res.status(200).send('Service is running');
  }

  // Signup (email/password) – optional; protect with ADMIN_SECRET if set
  if (req.method === 'POST' && req.path === '/auth/signup') {
    try {
      if (adminSecret && req.headers['x-admin-secret'] !== adminSecret) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const email = (req.body.email || '').toString().trim();
      const password = (req.body.password || '').toString();
      if (!email || !password) {
        return res
          .status(400)
          .json({ error: 'email and password are required' });
      }
      const user = await admin.auth().createUser({ email, password });
      // Issue ID token via Identity Toolkit (signInWithPassword)
      if (!apiKey) {
        return res
          .status(500)
          .json({ error: 'FIREBASE_WEB_API_KEY not set for issuing tokens' });
      }
      const tokenResp = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            email,
            password,
            returnSecureToken: true,
          }),
        }
      );
      const tokenJson = await tokenResp.json();
      if (!tokenResp.ok) {
        console.error('Sign-in after signup failed', tokenJson);
        return res
          .status(500)
          .json({ error: 'User created but token fetch failed' });
      }
      await setSessionCookie(res, tokenJson.idToken);
      return res.status(201).json({
        uid: user.uid,
        email: user.email,
      });
    } catch (err) {
      console.error('Signup failed', err);
      return res.status(500).json({ error: 'Unable to sign up user' });
    }
  }

  // Signin (email/password) → returns ID token
  if (req.method === 'POST' && req.path === '/auth/signin') {
    try {
      if (!apiKey) {
        return res
          .status(500)
          .json({ error: 'FIREBASE_WEB_API_KEY not set for issuing tokens' });
      }
      const email = (req.body.email || '').toString().trim();
      const password = (req.body.password || '').toString();
      if (!email || !password) {
        return res
          .status(400)
          .json({ error: 'email and password are required' });
      }
      const resp = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            email,
            password,
            returnSecureToken: true,
          }),
        }
      );
      const json = await resp.json();
      if (!resp.ok) {
        console.error('Signin failed', json);
        return res.status(401).json({ error: json.error?.message || 'Signin failed' });
      }
      await setSessionCookie(res, json.idToken);
      return res.json({ ok: true });
    } catch (err) {
      console.error('Signin error', err);
      return res.status(500).json({ error: 'Signin error' });
    }
  }

  // Signout -> clear session cookie
  if (req.method === 'POST' && req.path === '/auth/signout') {
    clearSessionCookie(res);
    return res.status(204).send('');
  }

  // Lookup by phone (requires ID token)
  if (
    req.method === 'POST' &&
    (req.path === '/table' || req.path === '/tables/lookup')
  ) {
    return requireSession(req, res, async () => {
      try {
        const phone =
          (req.body.phoneNumber ||
            req.body.phone ||
            req.body.phone_no ||
            '') +
          '';
        const trimmed = phone.trim();
        if (!trimmed) {
          return res.status(400).json({ error: 'phoneNumber is required' });
        }
        const doc = await tables.doc(trimmed).get();
        if (!doc.exists) {
          return res
            .status(404)
            .json({ error: 'No table found for that phone number.' });
        }
        const data = doc.data();
        return res.json({
          phoneNumber: trimmed,
          tableNumber: data.tableNumber,
        });
      } catch (err) {
        console.error('Lookup failed', err);
        return res.status(500).json({ error: 'Lookup failed' });
      }
    });
  }

  // Upsert table (requires ID token)
  if (req.method === 'PUT' && req.path === '/table') {
    return requireSession(req, res, async () => {
      try {
        const phone =
          (req.body.phoneNumber ||
            req.body.phone ||
            req.body.phone_no ||
            '') +
          '';
        const tableNumber =
          (req.body.tableNumber ||
            req.body.table ||
            req.body.table_no ||
            '') +
          '';
        const trimmedPhone = phone.trim();
        const trimmedTable = tableNumber.trim();
        if (!trimmedPhone || !trimmedTable) {
          return res
            .status(400)
            .json({ error: 'phoneNumber and tableNumber are required' });
        }
        await tables.doc(trimmedPhone).set({
          phoneNumber: trimmedPhone,
          tableNumber: trimmedTable,
          updatedBy: req.user.uid,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return res.json({
          phoneNumber: trimmedPhone,
          tableNumber: trimmedTable,
        });
      } catch (err) {
        console.error('Upsert failed', err);
        return res.status(500).json({ error: 'Unable to save record' });
      }
    });
  }

  return res.status(404).json({ error: 'Not found' });
});
