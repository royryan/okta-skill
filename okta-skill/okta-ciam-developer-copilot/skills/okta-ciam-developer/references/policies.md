# Okta Policies — Sessions, Authentication, MFA, Passwords

Derived from developer.okta.com: Policies concept, configure-signon-policy, configure-access-policy guides (Identity Engine). Verified 2026-07-05.

## Contents

1. [Policy landscape](#policy-landscape)
2. [Global session policy](#global-session-policy)
3. [Authentication policies (per-app)](#authentication-policies-per-app)
4. [Authenticator enrollment policy](#authenticator-enrollment-policy)
5. [Password policy](#password-policy)
6. [Authorization server access policies](#authorization-server-access-policies)
7. [Evaluation order](#evaluation-order)
8. [Terraform mapping](#terraform-mapping)
9. [CIAM policy recipes](#ciam-policy-recipes)

## Policy landscape

Identity Engine policy types (each = policy → prioritized rules; first matching rule wins):

| Policy | Governs | API `type` |
|---|---|---|
| Global session policy | How/whether an Okta session is created; primary-factor requirements per network/group | `OKTA_SIGN_ON` |
| Authentication policy | Per-app assurance: which authenticators, how many factors, re-auth frequency | `ACCESS_POLICY` |
| Authenticator enrollment | Which authenticators users may/must enroll, and when | `MFA_ENROLL` |
| Password | Complexity, history, lockout, recovery | `PASSWORD` |
| Profile enrollment | Self-service registration: fields, email verification, progressive profiling | `PROFILE_ENROLLMENT` |
| Routing rules (IdP discovery) | Which IdP handles a sign-in | `IDP_DISCOVERY` |

## Global session policy

- Org-wide; evaluated first at sign-in. Conditions: user/group, network zone, IdP, risk.
- Controls: allow/deny, MFA at session establishment (usually better left to per-app authentication policies on OIE), session lifetime & idle timeout, persistent cookie.
- Keep a low-priority catch-all rule; Okta ships a default policy that cannot be deleted.

## Authentication policies (per-app)

The OIE replacement for "app sign-on policies" — where MFA decisions belong.

- Each app is assigned exactly one authentication policy; policies are **shareable** across apps (manage a small set — "Any 1FA", "2FA always", "2FA phishing-resistant" — rather than one per app).
- Rules express **assurance**: e.g. "2 factor types, one possession-based, phishing-resistant only, device bound"; re-authentication frequency (`every sign-in`, `12 hours`, etc.).
- Conditions: group, device state (managed/registered — requires device integrations), platform, network zone, risk level, user type.
- Okta provides presets: "Any two factors", "Password only" (avoid for anything sensitive), "Phishing-resistant".
- CIAM note: for consumer apps, a common pattern is password or email-magic-link 1FA baseline + step-up rule (2FA) for a "high-value action" app or group.

## Authenticator enrollment policy

- Governs which authenticators (Okta Verify, FIDO2/WebAuthn, phone SMS/voice, email, password, security question, TOTP) are **enabled/required/optional** for enrollment, per group.
- Enrollment can be triggered at sign-in when a policy requires an authenticator the user lacks.
- Authenticators themselves are org-level objects — enable them (Security → Authenticators) before referencing them in policy. Terraform: `okta_authenticator`.

## Password policy

- Per-group; complexity (length, character classes, common-password check), history, min/max age, lockout (attempts, auto-unlock), recovery flows (email/SMS/security question).
- Recovery for CIAM: email magic link / OTP recovery is standard; disable security questions for better security posture.

## Authorization server access policies

Custom auth servers have their own **access policies** (Security → API → {server} → Access Policies): which clients get tokens, for which scopes, with what token lifetimes, whether refresh tokens rotate. Rule per grant type/scope-set. These are separate from the app's authentication policy (which governs the human sign-in).

## Evaluation order

1. Routing rules → which IdP.
2. Global session policy → may deny or set session requirements.
3. Authentication policy of the target app → assurance/step-up.
4. (OAuth flows) auth server access policy → token issuance, lifetimes, scopes.

## Terraform mapping

| Object | Resource |
|---|---|
| Global session policy / rules | `okta_policy_signon`, `okta_policy_rule_signon` |
| Authentication policy / rules (app) | `okta_app_signon_policy`, `okta_app_signon_policy_rule` |
| Assign policy to app | `okta_app_oauth.authentication_policy` attribute (or `okta_app_policy_assignment`) |
| Enrollment policy / rules | `okta_policy_mfa`, `okta_policy_rule_mfa` |
| Password policy / rules | `okta_policy_password`, `okta_policy_rule_password` |
| Profile enrollment | `okta_policy_profile_enrollment`, `okta_policy_profile_enrollment_apps` |
| Authenticators | `okta_authenticator` |
| Auth server access policy | `okta_auth_server_policy`, `okta_auth_server_policy_rule` |
| Network zones (conditions) | `okta_network_zone` |

Working examples: `scripts/07-policies-mfa/` and `assets/terraform-bootstrap/policies.tf`.

## CIAM policy recipes

- **Consumer baseline**: password (or email OTP) 1FA; enrollment policy offering email + optional Okta Verify/WebAuthn; self-service registration via profile enrollment policy; password policy with lockout + email recovery.
- **Step-up for sensitive actions**: separate OIDC app (or ACR values) with a "2FA, re-auth every session" authentication policy.
- **B2B tenant**: group per customer org; routing rule sends `@customer.com` logins to their enterprise IdP; authentication policy requiring 2FA for admin group.
- **Passwordless**: enable email + WebAuthn authenticators; authentication policy "1 possession factor, phishing-resistant"; password optional in enrollment policy.
