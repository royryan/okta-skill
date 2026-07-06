# Use case 05 — Manage users, groups, apps via the Management API

Pattern source: okta/okta-sdk-nodejs, okta/okta-sdk-python READMEs; developer.okta.com API reference. See `references/management-api.md` for auth setup (API Services app + okta.* scopes + admin roles).

## Files

- `okta.tf` — service app with granted okta.* scopes (Terraform-managed automation identity)
- `node/manage.js` — CRUD users/groups/apps with @okta/okta-sdk-nodejs
- `python/manage.py` — same with okta-sdk-python

## Rules of the road

- Private-key JWT auth (`AuthorizationMode: PrivateKey`), never SSWS tokens for new automation.
- Use `search` (indexed, SCIM-filter syntax) for user queries, not client-side filtering.
- SDK iterators auto-paginate; let them.
- 429s: SDKs retry using rate-limit headers — set sane `requestTimeout`/retry config and avoid tight parallel loops.
