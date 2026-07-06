# Use case 04 — Machine-to-machine auth (Client Credentials)

Pattern source: developer.okta.com/docs/guides/implement-grant-type/clientcreds/main/ and implement-oauth-for-okta-serviceapp.

A backend service gets its own access token — no user involved. Two targets:

1. **Your API** (custom auth server, custom scopes) — validate per use case 03.
2. **Okta management API** (org auth server, `okta.*` scopes) — see use case 05.

Prefer **private-key JWT** client auth over client secrets (required for okta.* scopes with key-based apps; better secret hygiene everywhere).

## Files

- `okta.tf` — API Services app with access-policy grant on the default auth server
- `node/client-credentials.js` — secret-based and private-key JWT variants
- `python/client_credentials.py` — same in Python

## Flow

```
POST {issuer}/v1/token
grant_type=client_credentials&scope=orders:read
+ client auth (Basic secret, or client_assertion private-key JWT)
```

Cache the token until `expires_in`; no refresh tokens for this grant.
