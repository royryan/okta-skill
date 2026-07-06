provider "okta" {
  org_name    = var.okta_org_name # subdomain only — never include "-admin"
  base_url    = var.okta_base_url
  client_id   = var.okta_client_id
  scopes      = var.okta_scopes
  private_key = var.okta_private_key

  max_retries     = 5
  request_timeout = 100
  # max_api_capacity = 80  # leave rate-limit headroom for other automation
}
