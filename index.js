// index.js
const admin = require('firebase-admin');
const functions = require('@google-cloud/functions-framework');
// Use native fetch when available (Node 18+), otherwise lazy-load node-fetch.
const fetch = globalThis.fetch
  ? globalThis.fetch
  : (...args) =>
      import('node-fetch').then(({ default: fetchFn }) => fetchFn(...args));
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'tablecheckingapp-13820',
  });
}

const db = admin.firestore();
const menuItems = db.collection('menuItems');
const orders = db.collection('orders');
const counters = db.collection('counters');

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

const toBase64String = (value) => {
  if (!value) return null;
  if (typeof value === 'string') {
    const trimmed = value.trim();
    return trimmed ? trimmed : null;
  }
  if (value instanceof admin.firestore.Blob) {
    return value.toBase64();
  }
  if (Buffer.isBuffer(value)) {
    return value.toString('base64');
  }
  return null;
};

const getNextTicketNumber = async () => {
  const counterRef = counters.doc('orderQueue');
  const nextValue = await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(counterRef);
    const current = snapshot.exists ? snapshot.data().value || 0 : 0;
    const next = Number(current) + 1;
    tx.set(counterRef, { value: next }, { merge: true });
    return next;
  });
  return nextValue;
};

const getNowServing = async () => {
  const doc = await counters.doc('nowServing').get();
  if (!doc.exists) return 1;
  const data = doc.data() || {};
  const value = Number(data.value || 1);
  return value > 0 ? value : 1;
};

const setNowServing = async (value) => {
  await counters.doc('nowServing').set({ value: Number(value) || 0 }, { merge: true });
  return Number(value) || 0;
};

const incrementNowServing = async () => {
  const counterRef = counters.doc('nowServing');
  const nextValue = await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(counterRef);
    const current = snapshot.exists ? snapshot.data().value || 0 : 0;
    const next = Number(current) + 1;
    tx.set(counterRef, { value: next }, { merge: true });
    return next;
  });
  return nextValue;
};

functions.http('helloHttp', async (req, res) => {
  const origin = pickOrigin(req);
  if (allowAnyOrigin && origin) {
    res.set('Access-Control-Allow-Origin', origin);
  }
  res.set('Access-Control-Allow-Credentials', 'true');
  res.set('Access-Control-Allow-Headers', 'Content-Type,x-admin-secret');
  res.set('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');

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

  // Menu list
  if (req.method === 'GET' && req.path === '/menu') {
    try {
      const snapshot = await menuItems.get();
      const data = snapshot.docs
        .map((doc) => {
          const raw = doc.data() || {};
          const imageBase64 = toBase64String(
            raw.imageBase64 || raw.image_base64 || raw.image,
          );
          const payload = {
            id: doc.id,
            ...raw,
          };
          if (imageBase64) {
            payload.imageBase64 = imageBase64;
            delete payload.image;
            delete payload.image_base64;
          }
          return payload;
        })
        .sort((a, b) => {
          const catA = (a.category || '').toString();
          const catB = (b.category || '').toString();
          if (catA !== catB) return catA.localeCompare(catB);
          const nameA = (a.name || '').toString();
          const nameB = (b.name || '').toString();
          return nameA.localeCompare(nameB);
        });
      return res.json({ items: data });
    } catch (err) {
      console.error('Menu fetch failed', err);
      return res.status(500).json({ error: 'Unable to load menu' });
    }
  }

  // Now serving (public)
  if (req.method === 'GET' && req.path === '/now-serving') {
    try {
      const value = await getNowServing();
      return res.json({ value });
    } catch (err) {
      console.error('Now serving fetch failed', err);
      return res.status(500).json({ error: 'Unable to load now serving' });
    }
  }

  // Set now serving (staff)
  if (req.method === 'POST' && req.path === '/now-serving') {
    return requireSession(req, res, async () => {
      try {
        const value = Number(req.body.value);
        if (!Number.isFinite(value)) {
          return res.status(400).json({ error: 'value is required' });
        }
        const updated = await setNowServing(value);
        return res.json({ value: updated });
      } catch (err) {
        console.error('Now serving update failed', err);
        return res.status(500).json({ error: 'Unable to update now serving' });
      }
    });
  }

  // Advance now serving by 1 (staff)
  if (req.method === 'POST' && req.path === '/now-serving/next') {
    return requireSession(req, res, async () => {
      try {
        const value = await incrementNowServing();
        return res.json({ value });
      } catch (err) {
        console.error('Now serving increment failed', err);
        return res.status(500).json({ error: 'Unable to advance now serving' });
      }
    });
  }

  // Create order (requires session)
  if (req.method === 'POST' && req.path === '/orders') {
    return requireSession(req, res, async () => {
      try {
        const items = Array.isArray(req.body.items) ? req.body.items : [];
        if (!items.length) {
          return res.status(400).json({ error: 'items are required' });
        }

        const subtotal = Number(req.body.subtotal || 0);
        const tax = Number(req.body.tax || 0);
        const total = Number(req.body.total || 0);
        const note = (req.body.note || '').toString();

        const ticketNumber = await getNextTicketNumber();
        const createdAt = admin.firestore.FieldValue.serverTimestamp();
        const docRef = await orders.add({
          items,
          subtotal,
          tax,
          total,
          note,
          ticketNumber: ticketNumber.toString(),
          status: 'placed',
          createdAt,
          userId: req.user.uid,
        });
        await setNowServing(ticketNumber);

        return res.status(201).json({
          orderId: docRef.id,
          ticketNumber: ticketNumber.toString(),
          subtotal,
          tax,
          total,
          createdAt: new Date().toISOString(),
        });
      } catch (err) {
        console.error('Order creation failed', err);
        return res.status(500).json({ error: 'Unable to place order' });
      }
    });
  }

  return res.status(404).json({ error: 'Not found' });
});
