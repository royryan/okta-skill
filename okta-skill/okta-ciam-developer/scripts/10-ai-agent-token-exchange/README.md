# Use case 10 — AI-agent auth: XAA / ID-JAG token exchange

Pattern source: developer.okta.com/docs/guides/ai-agent-token-exchange/-/main/ (verified 2026-07-05). Concepts: `references/ai-agent-auth.md`. Playground: xaa.dev.

**Prerequisites** (org-side, not automatable on a free dev org): Okta for AI Agents subscription; agent registered in the org with a keypair; resource connection (Authorization-server type) defined for the agent; an OIDC web app that signs users in via the **org authorization server**.

## Files

- `node/agent-exchange.js` — the two token-exchange calls
- `curl-flow.sh` — same flow as raw curl for debugging

## Flow recap

1. Web app signs user in (org auth server) → ID token.
2. Agent exchanges ID token → **ID-JAG** at `https://{org}.okta.com/oauth2/v1/token` (grant `token-exchange`, client auth = agent's private-key JWT).
3. Agent exchanges ID-JAG → access token at the resource's custom auth server (grant `jwt-bearer`).
4. Agent calls the resource API; resource validates the access token normally (use case 03).

ID-JAGs are short-lived (~5 min) — re-exchange, don't cache long.
