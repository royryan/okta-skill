# okta-ciam-developer — GitHub Copilot Skill

GitHub Copilot edition of the `okta-ciam-developer` skill: an offline-first Okta CIAM/developer toolkit with bundled reference docs, working code examples (Node, Python, Java/Spring, .NET, Go, React), and Terraform templates — all derived exclusively from [developer.okta.com](https://developer.okta.com) and [github.com/okta](https://github.com/okta). No internet access is required at usage time.

Structured per the [Agent Skills specification](https://agentskills.io/home) and the [Awesome GitHub Copilot skill-authoring guide](https://awesome-copilot.github.com/learning-hub/creating-effective-skills/).

## Installation

Copy the skill folder into your repository so Copilot discovers it automatically:

```bash
mkdir -p .github/skills
cp -r skills/okta-ciam-developer .github/skills/
```

Every team member with Copilot access to the repository gets the skill — no per-user setup.

## Usage

- **Slash command**: `/okta-ciam-developer add Okta sign-in to this Express app` (works mid-message too)
- **Agent discovery**: just describe the task — "protect this FastAPI service with Okta JWTs", "bootstrap a dev Okta tenant with Terraform" — and Copilot invokes the skill from its description

## What's inside

```
skills/okta-ciam-developer/
├── SKILL.md                      # workflow, task map, guardrails
├── references/                   # 10 offline docs: core concepts, OIDC/OAuth flows,
│                                 # SDK catalog (active vs archived), Management API,
│                                 # policies, Terraform v6.x, hooks, customization,
│                                 # AI-agent auth (XAA/ID-JAG), workforce SSO/SCIM
├── scripts/                      # top-10 use cases, each with Terraform + code
│   ├── 01-web-app-sign-in/       #   Node, Python, Spring Boot, ASP.NET Core, Go
│   ├── 02-spa-sign-in/           #   React, vanilla okta-auth-js
│   ├── 03-api-token-validation/  #   Node, Python, Java, Go, .NET
│   ├── 04-m2m-client-credentials/
│   ├── 05-management-api/
│   ├── 06-terraform-org-automation/
│   ├── 07-policies-mfa/
│   ├── 08-custom-domain-branding/
│   ├── 09-hooks/
│   └── 10-ai-agent-token-exchange/
└── assets/terraform-bootstrap/   # ready-to-apply tenant bootstrap:
                                  # groups, apps, auth server, policies
```

## Content provenance

All content verified against live official sources on **2026-07-05** (Terraform provider v6.12.0; SDK archival status as of 2026-07-01; ID-JAG token-exchange parameters from the current developer.okta.com guide). When online, spot-check version-sensitive facts — Okta archives SDKs regularly.
