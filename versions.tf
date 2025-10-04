terraform {
  required_version = ">= 1.7.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.2, < 6.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.3, < 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4, < 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 4.0"
    }
  }
}