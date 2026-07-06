# Use case 01 — Server-side web app sign-in (redirect, Auth Code + PKCE)

Pattern source: developer.okta.com/docs/guides/sign-into-web-app-redirect/{node-express|python|spring-boot|asp-net-core-3}/main/ and okta-samples/* repos.

Okta recommends the **redirect model**: your app redirects to Okta (hosted sign-in widget), Okta redirects back with a code. Node and Python use generic OIDC libraries by design — there is no dedicated Okta server-side SDK for them.

## Files

- `okta.tf` — provisions the OIDC Web app in Okta (Terraform)
- `node-express/server.js` — Express + passport-openidconnect
- `python-flask/app.py` — Flask + OIDC
- `spring-boot/` — Okta Spring Boot Starter (`application.properties` + controller)
- `aspnet-core/Program.cs` — Okta.AspNetCore middleware
- `go/main.go` — standard OIDC with Gorilla sessions

## Common configuration

All examples expect:

```
OKTA_OAUTH2_ISSUER=https://{org}.okta.com/oauth2/default
OKTA_OAUTH2_CLIENT_ID={clientId}
OKTA_OAUTH2_CLIENT_SECRET={clientSecret}
APP_BASE_URL=http://localhost:3000   # port varies per stack
```

Sign-in redirect URI registered in Okta must match exactly (see `okta.tf`).

## Gotchas

- Use the custom auth server (`/oauth2/default`) if you'll also call your own APIs with the access token; org server is fine for login-only.
- The user must be **assigned** to the app (directly or via group) or they'll get a 403 at sign-in.
- Session storage in these examples is in-memory — replace with Redis/DB in production.
