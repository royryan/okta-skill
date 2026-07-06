# Okta Hooks — Event Hooks and Inline Hooks

Derived from developer.okta.com: event-hook-implementation, token-inline-hook, registration-inline-hook, password-import-inline-hook guides and Hooks concept docs. Verified 2026-07-05.

## Contents

1. [Event hooks vs inline hooks](#event-hooks-vs-inline-hooks)
2. [Event hooks](#event-hooks)
3. [Inline hooks](#inline-hooks)
4. [Security and verification](#security-and-verification)
5. [Terraform mapping](#terraform-mapping)

## Event hooks vs inline hooks

| | Event hooks | Inline hooks |
|---|---|---|
| Direction | Okta → your endpoint, **async**, after the fact | Okta → your endpoint, **sync**, mid-flow; your response changes the flow |
| Use for | Notifications, SIEM, downstream sync (user created, app assigned) | Modify tokens, gate registration, import passwords, customize SAML |
| Failure impact | Retried; flow unaffected | Flow blocked/defaults applied — endpoint must be fast (<3 s) and highly available |

## Event hooks

- Subscribe to System Log event types (e.g. `user.lifecycle.create`, `user.account.lock`, `group.user_membership.add`, `application.user_membership.add`).
- **Verification handshake**: on registration Okta sends a one-time `GET` with header `x-okta-verification-challenge`; respond `200` with JSON `{ "verification": "<that value>" }`.
- Delivery: `POST` JSON; respond `2xx` quickly (do heavy work async). Okta retries on failure.
- Filtering (newer capability): event hooks support filters (Okta Expression Language) so only matching events fire.
- Alternative for polling: `GET /api/v1/logs?since=...` with cursor pagination.

## Inline hooks

All are REST callbacks: Okta POSTs a JSON payload; you respond with a JSON `commands` array.

| Hook | Fires | Typical commands |
|---|---|---|
| **Token inline hook** | During OIDC/OAuth token minting on a **custom auth server** | Add/modify/remove ID- and access-token claims (`com.okta.identity.patch`, `com.okta.access.patch` ops) |
| **Registration inline hook** | Self-service registration / progressive profiling submit | Allow/deny registration (`com.okta.action.update` → `DENY`), modify profile fields |
| **Password import inline hook** | First login of a user created with `credentials.password.hook` | Verify supplied password against your legacy store: respond `com.okta.action.update` → `VERIFIED` / `UNVERIFIED` (Okta stores the hash on VERIFIED — zero-downtime migration) |
| **SAML assertion inline hook** | SAML assertion minting | Patch assertion attributes |
| **Telephony inline hook** | SMS/voice OTP delivery | Route through your own telephony provider |

Token hook response example (add a claim to the access token):

```json
{
  "commands": [
    {
      "type": "com.okta.access.patch",
      "value": [
        { "op": "add", "path": "/claims/tenant", "value": "acme" }
      ]
    }
  ]
}
```

## Security and verification

- Endpoints must be HTTPS, publicly reachable, and authenticate Okta's calls — configure an auth header (secret) on the hook; validate it on every request.
- HMAC signature verification is available for hooks (signed request header) — prefer it over a static secret where supported.
- Never do slow work inline; inline hooks have short timeouts and failures degrade sign-in/registration UX.
- Return only documented commands; unknown commands are ignored.

## Terraform mapping

```hcl
resource "okta_event_hook" "user_created" {
  name   = "user-created-webhook"
  events = ["user.lifecycle.create", "user.lifecycle.activate"]
  channel = {
    type    = "HTTP"
    version = "1.0.0"
    uri     = "https://hooks.example.com/okta/events"
  }
  auth = {
    type  = "HEADER"
    key   = "Authorization"
    value = var.hook_shared_secret
  }
}

resource "okta_inline_hook" "token_enrichment" {
  name    = "token-enrichment"
  type    = "com.okta.oauth2.tokens.transform"
  version = "1.0.0"
  channel = {
    type    = "HTTP"
    version = "1.0.0"
    uri     = "https://hooks.example.com/okta/token"
    method  = "POST"
  }
  auth = {
    type  = "HEADER"
    key   = "Authorization"
    value = var.hook_shared_secret
  }
}
```

Inline hook `type` values: `com.okta.oauth2.tokens.transform` (token), `com.okta.user.pre-registration` (registration), `com.okta.user.credential.password.import`, `com.okta.saml.tokens.transform`, `com.okta.telephony.provider`.

Event hooks must be **activated** after creation (the verification handshake): the resource handles it if the endpoint is live; otherwise activate later via `POST /api/v1/eventHooks/{id}/lifecycle/activate`.

Working receiver example: `scripts/09-hooks/`.
