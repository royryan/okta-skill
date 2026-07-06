# Use case 06 — Terraform org automation (groups, users, apps)

Pattern source: developer.okta.com Terraform guides (terraform-manage-groups, terraform-manage-user-access, terraform-import-existing-resources). Provider setup: `references/terraform.md`. Full-tenant template: `assets/terraform-bootstrap/`.

## Files

- `main.tf` — groups, group rules, users, app assignments, import example

## Highlights

- `okta_group_rule` auto-assigns users by expression — don't also manage the same memberships statically.
- `okta_app_group_assignments` (plural) is the bulk, rate-limit-friendly way to assign.
- `import {}` blocks + `terraform plan -generate-config-out=` onboard existing orgs.
