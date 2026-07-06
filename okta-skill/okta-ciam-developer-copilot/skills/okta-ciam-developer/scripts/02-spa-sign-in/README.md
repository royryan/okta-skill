# Use case 02 — SPA sign-in (redirect model, PKCE, no client secret)

Pattern source: developer.okta.com/docs/guides/sign-into-spa-redirect/{react|angular|vue}/main/ and /docs/guides/auth-js-redirect/. SDKs: okta/okta-react, okta/okta-angular, okta/okta-vue — all wrap okta/okta-auth-js.

## Files

- `okta.tf` — provisions the SPA app + trusted origin
- `react/App.jsx` — okta-react with react-router
- `vanilla-js/index.js` — okta-auth-js directly (framework-agnostic)

Angular/Vue follow the same shape as React with `okta-angular`/`okta-vue`; the OktaAuth config object is identical.

## Key rules

- App type **SPA / browser**: `token_endpoint_auth_method = "none"`, PKCE required, never embed a client secret.
- Register the app's origin as a **Trusted Origin** (CORS + redirect) or token/logout calls fail in the browser.
- Redirect URI convention: `{origin}/login/callback`.
- Tokens are managed by `okta-auth-js` `tokenManager` (memory/sessionStorage; refresh-token rotation is on by default for SPAs).
- Send `getAccessToken()` as `Authorization: Bearer` to your API (validated per use case 03).
