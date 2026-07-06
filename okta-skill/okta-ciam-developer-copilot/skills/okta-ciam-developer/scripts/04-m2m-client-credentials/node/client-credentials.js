// Client Credentials flow — both client auth methods.
// Source pattern: developer.okta.com/docs/guides/implement-grant-type/clientcreds/main/
// npm i jsonwebtoken (only for the private-key JWT variant)

const jwt = require('jsonwebtoken');

const ISSUER = process.env.OKTA_OAUTH2_ISSUER; // custom server for your API scopes;
// use https://{org}.okta.com/oauth2 (org server) for okta.* management scopes.
const CLIENT_ID = process.env.OKTA_CLIENT_ID;

// --- Variant A: client secret (simpler, weaker) -----------------------------
async function tokenWithSecret(scope) {
  const res = await fetch(`${ISSUER}/v1/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization:
        'Basic ' + Buffer.from(`${CLIENT_ID}:${process.env.OKTA_CLIENT_SECRET}`).toString('base64'),
    },
    body: new URLSearchParams({ grant_type: 'client_credentials', scope }),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json(); // { access_token, expires_in, scope, token_type }
}

// --- Variant B: private-key JWT (recommended) --------------------------------
function buildClientAssertion(privateKeyPem) {
  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    {
      iss: CLIENT_ID,
      sub: CLIENT_ID,
      aud: `${ISSUER}/v1/token`,
      iat: now,
      exp: now + 300,
      jti: crypto.randomUUID(),
    },
    privateKeyPem,
    { algorithm: 'RS256', keyid: process.env.OKTA_KEY_ID } // kid must match registered JWKS
  );
}

async function tokenWithPrivateKey(scope) {
  const assertion = buildClientAssertion(process.env.OKTA_PRIVATE_KEY);
  const res = await fetch(`${ISSUER}/v1/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'client_credentials',
      scope,
      client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion: assertion,
    }),
  });
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

// Simple in-memory token cache — always cache until expiry
let cached = null;
async function getToken(scope = 'orders:read') {
  if (cached && cached.expiresAt > Date.now() + 30_000) return cached.token;
  const t = await tokenWithPrivateKey(scope);
  cached = { token: t.access_token, expiresAt: Date.now() + t.expires_in * 1000 };
  return cached.token;
}

module.exports = { getToken, tokenWithSecret, tokenWithPrivateKey };
