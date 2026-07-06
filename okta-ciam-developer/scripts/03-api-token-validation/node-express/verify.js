// Protect an Express API with @okta/jwt-verifier.
// Source pattern: developer.okta.com/docs/guides/protect-your-api/nodeexpress/main/
// npm i express @okta/jwt-verifier

const express = require('express');
const OktaJwtVerifier = require('@okta/jwt-verifier');

const oktaJwtVerifier = new OktaJwtVerifier({
  issuer: process.env.OKTA_OAUTH2_ISSUER, // https://{org}.okta.com/oauth2/default
  // assertClaims can pin cid to known clients if desired
});

const AUDIENCE = process.env.OKTA_OAUTH2_AUDIENCE || 'api://default';

function authRequired(requiredScopes = []) {
  return async (req, res, next) => {
    try {
      const match = (req.headers.authorization || '').match(/^Bearer (.+)$/);
      if (!match) return res.status(401).json({ error: 'missing bearer token' });

      const jwt = await oktaJwtVerifier.verifyAccessToken(match[1], AUDIENCE);
      const scopes = jwt.claims.scp || [];
      if (!requiredScopes.every(s => scopes.includes(s))) {
        return res.status(403).json({ error: 'insufficient scope' });
      }
      req.jwt = jwt;
      next();
    } catch (err) {
      res.status(401).json({ error: err.message });
    }
  };
}

const app = express();

app.get('/api/orders', authRequired(['orders:read']), (req, res) =>
  res.json({ orders: [], sub: req.jwt.claims.sub })
);

app.post('/api/orders', authRequired(['orders:write']), (req, res) =>
  res.status(201).json({ created: true })
);

app.listen(8000, () => console.log('API on :8000'));
