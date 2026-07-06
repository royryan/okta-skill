# Okta SDK Catalog — Active vs Archived

Verified 2026-07-01 against developer.okta.com/code/ and github.com/okta. Only officially supported, **non-archived** repos are listed as recommended. If internet is available, re-verify archival status before recommending; Okta archives SDKs regularly.

## Contents

1. [Sign in — web apps (server-side)](#sign-in--web-apps-server-side)
2. [Sign in — SPAs](#sign-in--spas)
3. [Sign in — mobile](#sign-in--mobile)
4. [JWT verifiers (protect your API)](#jwt-verifiers-protect-your-api)
5. [Management SDKs](#management-sdks)
6. [Infrastructure & tooling](#infrastructure--tooling)
7. [Archived — do NOT recommend](#archived--do-not-recommend)

## Sign in — web apps (server-side)

Okta's guidance for several languages is a **generic OIDC library**, not a dedicated Okta SDK.

| Language/Framework | Recommended | Repo | Guide (developer.okta.com) |
|---|---|---|---|
| Node.js / Express | `passport` + `passport-openidconnect` (generic) | okta-samples/okta-express-sample | /docs/guides/sign-into-web-app-redirect/node-express/main/ |
| Python / Flask | Flask + OIDC client, flask-login (generic) | okta-samples/okta-flask-sample | /docs/guides/sign-into-web-app-redirect/python/main/ |
| Java / Spring Boot | Okta Spring Boot Starter | okta/okta-spring-boot | /docs/guides/sign-into-web-app-redirect/spring-boot/main/ |
| Java (Micronaut) | Micronaut security-oauth2 | okta/samples-java-micronaut | sample only |
| ASP.NET Core / .NET | Okta ASP.NET middleware | okta/okta-aspnet | /docs/guides/sign-into-web-app-redirect/asp-net-core-3/main/ |
| Blazor Server | Okta ASP.NET middleware | okta/okta-aspnet | sample only |
| Go | Standard OIDC w/ Gorilla sessions (generic) | — | /docs/guides/sign-into-web-app-redirect/go/main/ |
| PHP | **No supported SDK** — generic OIDC library | — | — |

## Sign in — SPAs

All wrap/depend on `okta-auth-js`. Redirect model is the recommended default.

| Framework | SDK | Repo | Guide |
|---|---|---|---|
| Vanilla JS | Okta Auth JS | okta/okta-auth-js | /docs/guides/auth-js-redirect/ |
| React | Okta React | okta/okta-react | /docs/guides/sign-into-spa-redirect/react/main/ |
| Angular | Okta Angular | okta/okta-angular | /docs/guides/sign-into-spa-redirect/angular/main/ |
| Vue | Okta Vue | okta/okta-vue | /docs/guides/sign-into-spa-redirect/vue/main/ |
| Embedded widget | Okta Sign-In Widget | okta/okta-signin-widget | /docs/guides/embedded-siw/ |

## Sign in — mobile

| Platform | Redirect auth | Embedded/native forms | Custom authenticator (push) |
|---|---|---|---|
| iOS | okta/okta-mobile-swift | okta/okta-idx-swift | okta/okta-devices-swift |
| Android | okta/okta-mobile-kotlin | okta/okta-idx-android | okta/okta-devices-kotlin |
| React Native | okta/okta-react-native (subset of native features) | — | — |

## JWT verifiers (protect your API)

| Language | Library | Repo |
|---|---|---|
| Node.js | `@okta/jwt-verifier` | okta/okta-jwt-verifier-js |
| Python | `okta-jwt-verifier` | okta/okta-jwt-verifier-python |
| Java | `okta-jwt-verifier` | okta/okta-jwt-verifier-java |
| Go | `okta-jwt-verifier-golang` | okta/okta-jwt-verifier-golang |
| .NET | built into ASP.NET Core JWT bearer middleware | see developer.okta.com/code/dotnet/jwt-validation/ |

## Management SDKs

All target the Okta Management API (`/api/v1/*`).

| Language | Package | Repo |
|---|---|---|
| Node.js | `@okta/okta-sdk-nodejs` | okta/okta-sdk-nodejs |
| Python | `okta` | okta/okta-sdk-python |
| Java | `com.okta.sdk:okta-sdk-api` | okta/okta-sdk-java |
| Go | `okta-sdk-golang/v6` (v6 required by TF provider contributions) | okta/okta-sdk-golang |
| .NET | `Okta.Sdk` | okta/okta-sdk-dotnet |

## Infrastructure & tooling

| Tool | Repo | Notes |
|---|---|---|
| Terraform provider | okta/terraform-provider-okta | **v6.x current** (v6.12.0, June 2026); 5.x deprecated. See `terraform.md`. |
| Okta MCP server | okta/okta-mcp-server | Self-hosted MCP server for AI agents/LLMs → scoped management APIs. See `ai-agent-auth.md`. |
| Okta CLI | — | Deprecated for org management; prefer Terraform/API. |
| Sign-In Widget | okta/okta-signin-widget | Hosted (recommended) or embedded. |
| Developer docs source | okta/okta-developer-docs | The docs site itself; useful for reading guides as markdown. |

## Archived — do NOT recommend

- **okta/okta-sdk-php** — archived. No supported Okta PHP SDK exists; use a generic OIDC library.
- **okta/okta-idx-golang** — archived. Use redirect-based auth for Go.
- **okta/samples-golang** — archived alongside it.
- **okta-oidc-js monorepo** (`@okta/oidc-middleware` etc.) — long archived; superseded by the per-framework SDKs above and generic OIDC libraries.

When online, check the repo's GitHub page banner for "This repository has been archived" before recommending anything not listed here.
