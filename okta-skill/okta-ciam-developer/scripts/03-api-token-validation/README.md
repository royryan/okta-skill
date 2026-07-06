# Use case 03 — Protect your API: local JWT validation

Pattern source: developer.okta.com/docs/guides/validate-access-tokens/ + protect-your-api guides; okta/okta-jwt-verifier-{js,python,java,golang}.

Validate access tokens **locally** (signature via JWKS, `iss`, `aud`, `exp`, scopes). Tokens must come from a **custom authorization server** (e.g. `/oauth2/default`) — org-server access tokens cannot be validated by your code.

## Files

- `okta.tf` — custom scopes on the default auth server
- `node-express/verify.js` — @okta/jwt-verifier middleware
- `python-fastapi/main.py` — okta-jwt-verifier
- `java-spring/SecurityConfig.java` — Spring resource server via Okta starter
- `go/main.go` — okta-jwt-verifier-golang
- `dotnet/Program.cs` — built-in JWT bearer middleware

## Checklist per request

1. Signature against `{issuer}/v1/keys` (verifier libs cache + handle rotation).
2. `iss` exact match; `aud` = your API audience (`api://default` unless changed).
3. `exp`/`iat` with small leeway.
4. Enforce `scp` claims per route (`orders:read` etc.).
5. Return `401` for invalid tokens, `403` for missing scopes.
