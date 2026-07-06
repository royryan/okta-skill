// Hook receiver: event-hook handshake + delivery, and a token inline hook.
// Source patterns: developer.okta.com/docs/guides/event-hook-implementation/
// and /docs/guides/token-inline-hook/.
// npm i express

const express = require('express');
const app = express();
app.use(express.json());

const SHARED_SECRET = process.env.HOOK_SHARED_SECRET;

// Authenticate every Okta call (secret set on the hook's auth config)
app.use('/okta', (req, res, next) => {
  if (req.headers.authorization !== SHARED_SECRET) return res.sendStatus(401);
  next();
});

// --- Event hook -------------------------------------------------------------

// One-time verification handshake: echo the challenge header
app.get('/okta/events', (req, res) => {
  res.json({ verification: req.headers['x-okta-verification-challenge'] });
});

// Async delivery: ack fast, process out-of-band
app.post('/okta/events', (req, res) => {
  res.sendStatus(200); // ack immediately — Okta retries on failure
  for (const event of req.body?.data?.events ?? []) {
    // e.g. user.lifecycle.create → sync to CRM, notify Slack, seed app DB
    console.log(event.eventType, event.target?.map(t => t.alternateId));
  }
});

// --- Token inline hook (com.okta.oauth2.tokens.transform) --------------------

app.post('/okta/token-hook', (req, res) => {
  const userProfile = req.body?.data?.context?.user?.profile ?? {};

  // Respond within the timeout — no slow lookups here
  res.json({
    commands: [
      {
        type: 'com.okta.access.patch',
        value: [
          { op: 'add', path: '/claims/customerTier', value: userProfile.customerTier || 'free' },
        ],
      },
      {
        type: 'com.okta.identity.patch',
        value: [
          { op: 'add', path: '/claims/displayTier', value: userProfile.customerTier || 'free' },
        ],
      },
    ],
  });
});

app.listen(8443, () => console.log('hook receiver up'));
