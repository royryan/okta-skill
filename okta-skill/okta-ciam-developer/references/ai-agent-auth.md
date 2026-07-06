# AI-Agent Auth with Okta — Cross App Access (XAA), ID-JAG, MCP Server

Secondary scope. Derived from developer.okta.com: ai-agent-token-exchange guide, mcp-server concept + implementation guide, Cross App Access blog series (2025-09-03 cross-app-access, 2026-01-20 xaa-dev-playground, 2026-02-10 xaa-client, 2026-02-17 xaa-resource-app). Verified 2026-07-05.

## Contents

1. [Landscape](#landscape)
2. [Cross App Access (XAA) and ID-JAG](#cross-app-access-xaa-and-id-jag)
3. [AI agent token exchange flow](#ai-agent-token-exchange-flow)
4. [Okta MCP server](#okta-mcp-server)
5. [Practical guidance](#practical-guidance)

## Landscape

Three distinct problems, three solutions:

| Problem | Solution |
|---|---|
| An AI agent needs to act on a user's behalf against enterprise apps | **XAA / AI agent token exchange (ID-JAG)** |
| An LLM/agent needs to administer an Okta org via natural language | **Okta MCP server** |
| A service/agent needs its own identity for API calls | Standard **client credentials** (see `oidc-oauth-flows.md`) |

Prerequisite for agent flows: the org is subscribed to **Okta for AI Agents**, agents are **registered** in the org, and **resource connections** define what each agent may access.

## Cross App Access (XAA) and ID-JAG

- XAA is Okta's implementation of the emerging IETF **Identity Assertion JWT Authorization Grant** OAuth extension — closing the OAuth gap where app-to-app/agent-to-app access relied on per-user consent screens, replacing it with enterprise-administered access.
- **ID-JAG** (Identity Assertion JWT Authorization Grant token): a JWT that asserts "this agent acts for this authenticated user toward this audience," issued by the **org authorization server**, exchangeable at a **custom authorization server** for a normal access token.
- Playground: **xaa.dev** — free environment to run the whole exchange end-to-end.
- Resource connection types an agent can be wired to: Authorization server (→ ID-JAG/XAA), Secret (vaulted in Okta Privileged Access), Service account (vaulted static credential), Resource server (third-party token brokered by Okta, requires user consent).

## AI agent token exchange flow

Five steps (Authorization-server resource type):

1. User signs in to the web app via **org authorization server** (Auth Code + PKCE) → app gets an ID token. (Must be the org server, not a custom one.)
2. App hands the ID token to the agent.
3. Agent → org server `/oauth2/v1/token`: **token exchange** for an ID-JAG:

```http
POST /oauth2/v1/token
grant_type=urn:ietf:params:oauth:grant-type:token-exchange
&requested_token_type=urn:ietf:params:oauth:token-type:id-jag
&subject_token={the user's ID token}
&subject_token_type=urn:ietf:params:oauth:token-type:id_token
&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer
&client_assertion={JWT signed with the agent's registered private key}
&audience={issuer URL of the resource's custom auth server, e.g. https://org.okta.com/oauth2/default}
&scope={scopes at the resource, e.g. chat.read chat.history}
```

Response: `issued_token_type: urn:ietf:params:oauth:token-type:id-jag`, short-lived (`expires_in` ~300).

4. Agent → the resource's **custom auth server** `/v1/token`: exchange ID-JAG for an access token:

```http
grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer
&assertion={the ID-JAG}
&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer
&client_assertion={agent's signed JWT}
```

Response: normal Bearer access token (~3600 s), revocable like any Okta access token.

5. Agent calls the resource API with the access token. The resource validates it like any custom-auth-server JWT (see `oidc-oauth-flows.md` §Token validation).

Runnable walk-through: `scripts/10-ai-agent-token-exchange/`.

## Okta MCP server

`github.com/okta/okta-mcp-server` — self-hosted (Python) MCP server exposing scoped Okta **management** operations as MCP tools:

- Capabilities: user management, group administration, app management, policy/security management, system-log queries.
- Auth modes: **Device Authorization Grant** (interactive/local dev) or **Private Key JWT** (headless/CI).
- Security model: least privilege via granted `okta.*` scopes on the underlying API service app; every action lands in the System Log for audit.
- Use it when the ask is "let Claude/Copilot manage my Okta org," not for customer-facing auth.

## Practical guidance

- Agent identity ≠ user identity: the agent authenticates itself with private-key JWT **and** carries the user context via ID-JAG. Never share user refresh tokens with agents.
- Scope ID-JAG requests to the minimum resource scopes; lifetimes are intentionally short — build re-exchange into the agent loop.
- The `/token` endpoint's standard OAuth 2.0 Token Exchange support (RFC 8693 semantics) is the underlying machinery; parameter values above are exact and must not be improvised.
- Feature availability: Okta for AI Agents is a subscription feature — check with the account team; don't assume it exists on a developer org.
