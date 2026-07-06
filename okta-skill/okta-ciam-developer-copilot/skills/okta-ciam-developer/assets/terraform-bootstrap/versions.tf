terraform {
  required_version = ">= 1.5.0"

  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 6.0" # 5.x is deprecated
    }
  }
}
