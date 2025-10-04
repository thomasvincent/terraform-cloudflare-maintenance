provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "random" {}

provider "external" {}

provider "local" {}