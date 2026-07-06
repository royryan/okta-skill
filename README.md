# Okta CIAM Developer Skill

An AI skill that turns Claude or GitHub Copilot into an effective Okta CIAM/developer assistant. Everything the assistant needs is bundled: curated reference documentation, working code examples in every officially supported stack, and ready-to-apply Terraform templates.

All content is derived **exclusively from official Okta sources** — [developer.okta.com](https://developer.okta.com) and [github.com/okta](https://github.com/okta) — and was verified against the live sources on **2026-07-05**. No blogs, no Stack Overflow, no stale training-data guesses.

## Why this exists

Okta's recommended integration paths change frequently: whole SDKs get archived (the PHP SDK and Go IDX SDK both were), languages shift from dedicated SDKs to generic OIDC libraries, and guides get restructured. AI assistants working from training data alone routinely recommend archived SDKs and invented API shapes. This skill fixes that by grounding the assistant in verified, bundled content.

## What's covered

Primary scope is **CIAM (Customer Identity) and developer workflows**, with AI-agent and workforce use cases secondary:

| # | Use case | Stacks included |
|---|---|---|
| 01 | Server-side web app sign-in (Auth Code + PKCE) | Node/Express, Python/Flask, Spring Boot, ASP.NET Core, Go |
| 02 | SPA sign-in (redirect model) | React, vanilla `okta-auth-js` (Angular/Vue notes) |
| 03 | API protection / local JWT validation | Node, Python/FastAPI, Java/Spring, Go, .NET |
| 04 | Machine-to-machine (client credentials, private-key JWT) | Node, Python |
| 05 | User/group/app automation via Management API | Node, Python SDKs |
| 06 | Terraform org automation (groups, rules, schema, imports) | Terraform (provider v6.x) |
| 07 | MFA, authenticators, sign-on policies | Terraform |
| 08 | Custom domain, branding, email | Terraform |
| 09 | Event hooks & inline hooks (incl. token enrichment) | Terraform + Node receiver |
| 10 | AI-agent auth — Cross App Access (XAA) / ID-JAG token exchange | Node + curl |

Every use case ships with its own Terraform to provision the Okta side. Ten reference documents cover core concepts (org vs custom authorization servers, Identity Engine), OIDC/OAuth flows, the SDK catalog (active **vs archived**), Management API best practices, policies, the Terraform provider, hooks, customization, AI-agent auth, and workforce SSO/SCIM.

Plus **[`assets/terraform-bootstrap/`](okta-ciam-developer/assets/terraform-bootstrap/)** — a complete, ready-to-apply Terraform structure that bootstraps an Okta tenant end-to-end: groups, web app + SPA + M2M service integration, a custom authorization server with scopes/claims/access policies, and baseline authentication/enrollment/password policies.

## Repository layout

```
.
├── okta-ciam-developer/            # Claude edition (Agent Skills format)
│   ├── SKILL.md
│   ├── references/                 # 10 offline reference docs
│   ├── scripts/                    # top-10 use case examples (Terraform + code)
│   └── assets/terraform-bootstrap/ # tenant bootstrap template
├── okta-ciam-developer.skill       # prebuilt package for one-click Claude install
├── okta-ciam-developer-copilot/    # GitHub Copilot edition
│   ├── README.md
│   └── skills/okta-ciam-developer/ # same bundle, Copilot-convention SKILL.md
├── LICENSE                         # MIT
└── README.md                       # this file
```

Both editions share identical bundled content; only the `SKILL.md` differs, following each platform's authoring conventions.

## Installation — Claude

**Claude.ai / Claude Desktop (including Cowork):**

1. Download [`okta-ciam-developer.skill`](okta-ciam-developer.skill) from this repo (or zip the `okta-ciam-developer/` folder).
2. Go to **Settings → Capabilities → Skills → Upload skill** and select the file.
3. Toggle the skill on. Done — Claude invokes it automatically whenever a conversation involves Okta.

**Claude Code (CLI):**

```bash
# Project-scoped (shared with your team via the repo):
mkdir -p .claude/skills
cp -r okta-ciam-developer .claude/skills/

# Or personal (available in all your projects):
mkdir -p ~/.claude/skills
cp -r okta-ciam-developer ~/.claude/skills/
```

Claude Code discovers the skill automatically; no restart needed.

**Verify:** ask *"Which SDK should I use for Okta sign-in in a PHP app?"* — a correctly installed skill answers that the PHP SDK is archived and recommends a generic OIDC library, citing its bundled SDK catalog.

## Installation — GitHub Copilot in Visual Studio Code

1. Copy the Copilot edition into the repository where you want the skill available:

   ```bash
   mkdir -p .github/skills
   cp -r okta-ciam-developer-copilot/skills/okta-ciam-developer .github/skills/
   ```

2. Commit and push. Everyone with Copilot access to the repository gets the skill automatically — no per-user setup.
3. In VS Code, make sure the **GitHub Copilot** extension is installed and up to date, and open a workspace containing the repo.

**Usage in VS Code:**

- **Automatic**: describe an Okta task in Copilot Chat — *"protect this FastAPI service with Okta JWTs"* — and Copilot discovers the skill via its description.
- **Explicit**: invoke it as a slash command anywhere in your message: `/okta-ciam-developer add Okta sign-in to this Express app`.

See [`okta-ciam-developer-copilot/README.md`](okta-ciam-developer-copilot/README.md) for details.

## Example prompts

- "Add Okta sign-in to my Express app"
- "Validate Okta access tokens in this Spring Boot API and enforce an `orders:read` scope"
- "Bootstrap a dev Okta tenant with Terraform — web app, SPA, custom auth server, 2FA policy"
- "Set up a token inline hook that adds a customerTier claim"
- "How does an AI agent exchange a user's ID token for an ID-JAG?"

## Content provenance & freshness

- SDK recommendations verified against `developer.okta.com/code/` and `github.com/okta` (2026-07-01); archived repos are explicitly flagged.
- Terraform guidance targets provider **v6.x** (v6.12.0, June 2026); 5.x is deprecated.
- AI-agent auth (XAA/ID-JAG) parameters match the current `developer.okta.com` AI agent token exchange guide.
- Each reference file carries its verification date. The skill instructs the assistant to spot-check version-sensitive facts against live sources when internet is available — and to say what was checked when it isn't.

## Contributing / updating

Okta moves fast. To refresh the bundle: re-verify `references/sdk-catalog.md` against live sources, bump the `content-verified` date in both `SKILL.md` frontmatters, and keep the two editions' bundled content in sync (they are intentionally identical below `references/`, `scripts/`, and `assets/`).

## License

[MIT](LICENSE). Not affiliated with or endorsed by Okta, Inc. Okta is a trademark of Okta, Inc.
