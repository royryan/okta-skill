# Okta Management API — Automation Best Practices

Derived from developer.okta.com API reference, implement-oauth-for-okta-serviceapp guide, and rate-limit docs. Verified 2026-07-05.

## Contents

1. [Authentication options](#authentication-options)
2. [OAuth 2.0 for Okta APIs (recommended)](#oauth-20-for-okta-apis-recommended)
3. [Core endpoints](#core-endpoints)
4. [Pagination, filtering, search](#pagination-filtering-search)
5. [Rate limits](#rate-limits)
6. [Error handling](#error-handling)
7. [SDK usage](#sdk-usage)

## Authentication options

| Method | Header | Status |
|---|---|---|
| **OAuth 2.0 access token** (service app, `okta.*` scopes) | `Authorization: Bearer {token}` | **Recommended** — least privilege, auditable, key-based |
| SSWS API token | `Authorization: SSWS {token}` | Legacy. Inherits the creating admin's full permissions; expires after 30 days of non-use. Avoid for new automation. |

## OAuth 2.0 for Okta APIs (recommended)

Same model the Terraform provider uses:

1. Create an **API Services** app (Admin Console → Applications → Create App Integration → API Services).
2. Client auth: **Public key / Private key** (private-key JWT). Generate the keypair in Okta (copy the PEM once — it is shown once) or supply your own public key. PKCS#1 format (`-----BEGIN RSA PRIVATE KEY-----`) is required by some tooling (Terraform provider).
3. **Grant Okta API scopes** on the app's "Okta API Scopes" tab — e.g. `okta.users.read`, `okta.users.manage`, `okta.groups.manage`, `okta.apps.manage`, `okta.policies.manage`, `okta.logs.read`. Granting scopes requires a super admin.
4. **Assign admin roles** to the app (Admin roles tab) — scopes alone are not sufficient; the app also needs role permissions covering the actions (e.g. Organization Administrator, or a narrow custom role for production).
5. Get tokens via client credentials + private-key JWT against the **org authorization server**: `POST https://{org}.okta.com/oauth2/v1/token` with `grant_type=client_credentials&scope=okta.users.read ...` and a signed `client_assertion`.

Scope naming maps to admin actions: `okta.{resource}.read` / `okta.{resource}.manage`. Full list: developer.okta.com/docs/api/oauth2/ (Okta Admin Management).

## Core endpoints

Base: `https://{org}.okta.com/api/v1`

| Resource | Endpoints (representative) |
|---|---|
| Users | `GET/POST /users`, `GET/POST /users/{id}`, lifecycle: `POST /users/{id}/lifecycle/{activate\|deactivate\|suspend\|unsuspend\|reset_password\|expire_password}` |
| Groups | `GET/POST /groups`, `PUT/DELETE /groups/{id}/users/{userId}`, `GET /groups/{id}/users` |
| Apps | `GET/POST /apps`, `POST /apps/{id}/lifecycle/{activate\|deactivate}`, assignments: `PUT /apps/{id}/users/{userId}`, `PUT /apps/{id}/groups/{groupId}` |
| Group rules | `GET/POST /groups/rules`, `POST /groups/rules/{id}/lifecycle/activate` |
| Policies | `GET/POST /policies?type=...`, `/policies/{id}/rules` |
| System log | `GET /logs?since=...&filter=...` (poll with `after` cursor from `Link` header) |
| Sessions | `DELETE /users/{id}/sessions` (revoke all) |
| Factors/Authenticators | `GET /users/{id}/factors`, org-level `/authenticators` |

User creation options: `POST /users?activate=true` with `profile` (+ optional `credentials`); use `provider: true` behavior via credentials object for federated/imported users; password-import via inline hook (see `hooks-events.md`).

## Pagination, filtering, search

- Pagination is cursor-based: follow the `Link: <...>; rel="next"` response header; `limit` param sets page size (max commonly 200 for users).
- **`search`** (users): SCIM-filter-style, indexed, supports all profile attributes, `sw`/`eq`/`gt` etc. — preferred: `search=profile.department eq "Engineering"`.
- `filter` is the older, limited variant; `q` is simple name/email prefix matching.
- SDK list methods return async iterators/collections that auto-paginate — use them instead of manual Link parsing.

## Rate limits

- Limits are per-endpoint-class per-minute per-org and vary by SKU (check response headers: `X-Rate-Limit-Limit`, `-Remaining`, `-Reset`).
- On `429`: back off until `X-Rate-Limit-Reset` (epoch seconds), then retry. Official SDKs and the Terraform provider have built-in retry; configure `max_retries`/backoff rather than hand-rolling.
- Reduce pressure: cache reads, use `search` not client-side filtering, batch via group assignment instead of per-user app assignment, spread bulk jobs.
- Concurrent-request limits also exist; avoid >an handful of parallel management-API calls per org.

## Error handling

Error body shape:

```json
{
  "errorCode": "E0000007",
  "errorSummary": "Not found: Resource not found: ...",
  "errorLink": "E0000007",
  "errorId": "...",
  "errorCauses": []
}
```

Common codes: `E0000007` not found, `E0000011` invalid token, `E0000038` operation on inactive resource, `E0000047` rate limit (with 429), `E0000001` API validation (see `errorCauses` for field-level details).

## SDK usage

Prefer the official management SDKs (`sdk-catalog.md` §Management SDKs) over raw HTTP: they handle OAuth private-key JWT auth, pagination, retries, and typed models. Working examples: `scripts/05-management-api/`.

Configuration convention (env vars respected by most Okta SDKs):

```
OKTA_CLIENT_ORGURL=https://dev-123456.okta.com
OKTA_CLIENT_AUTHORIZATIONMODE=PrivateKey
OKTA_CLIENT_CLIENTID={clientId}
OKTA_CLIENT_SCOPES="okta.users.read okta.groups.manage"
OKTA_CLIENT_PRIVATEKEY={PEM or path}
```
