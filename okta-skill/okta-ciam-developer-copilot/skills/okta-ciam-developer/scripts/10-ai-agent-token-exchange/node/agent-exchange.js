// AI agent token exchange (XAA / ID-JAG), per
// developer.okta.com/docs/guides/ai-agent-token-exchange/-/main/ (verified 2026-07-05).
// npm i jsonwebtoken

const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const ORG_URL = process.env.OKTA_ORG_URL;               // https://{org}.okta.com
const AGENT_CLIENT_ID = process.env.AGENT_CLIENT_ID;    // from agent registration
const AGENT_PRIVATE_KEY = process.env.AGENT_PRIVATE_KEY; // key registered with the agent
const AGENT_KEY_ID = process.env.AGENT_KEY_ID;

function clientAssertion(audience) {
  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    { iss: AGENT_CLIENT_ID, sub: AGENT_CLIENT_ID, aud: audience, iat: now, exp: now + 300, jti: crypto.randomUUID() },
    AGENT_PRIVATE_KEY,
    { algorithm: 'RS256', keyid: AGENT_KEY_ID }
  );
}

// Step 1 of 2: user's ID token -> ID-JAG (org authorization server)
async function exchangeIdTokenForIdJag(userIdToken, resourceIssuer, scopes) {
  const tokenUrl = `${ORG_URL}/oauth2/v1/token`;
  const res = await fetch(tokenUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:token-exchange',
      requested_token_type: 'urn:ietf:params:oauth:token-type:id-jag',
      subject_token: userIdToken,
      subject_token_type: 'urn:ietf:params:oauth:token-type:id_token',
      client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion: clientAssertion(tokenUrl),
      audience: resourceIssuer,             // e.g. `${ORG_URL}/oauth2/default`
      scope: scopes.join(' '),              // scopes at the resource
    }),
  });
  if (!res.ok) throw new Error(`ID-JAG exchange failed: ${await res.text()}`);
  return (await res.json()).access_token;    // issued_token_type: ...:id-jag, ~300s TTL
}

// Step 2 of 2: ID-JAG -> access token (resource's custom authorization server)
async function exchangeIdJagForAccessToken(idJag, resourceIssuer) {
  const tokenUrl = `${resourceIssuer}/v1/token`;
  const res = await fetch(tokenUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: idJag,
      client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion: clientAssertion(tokenUrl),
    }),
  });
  if (!res.ok) throw new Error(`access-token exchange failed: ${await res.text()}`);
  return res.json(); // { token_type: "Bearer", access_token, expires_in, scope }
}

// Agent loop usage:
async function actForUser(userIdToken) {
  const resourceIssuer = `${ORG_URL}/oauth2/default`;
  const idJag = await exchangeIdTokenForIdJag(userIdToken, resourceIssuer, ['chat.read', 'chat.history']);
  const { access_token } = await exchangeIdJagForAccessToken(idJag, resourceIssuer);
  return fetch('https://resource.example.com/api/chat', {
    headers: { Authorization: `Bearer ${access_token}` },
  });
}

module.exports = { exchangeIdTokenForIdJag, exchangeIdJagForAccessToken, actForUser };
