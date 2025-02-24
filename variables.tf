variable "cloudflare_account_id" {
  type        = string
  description = "Your Cloudflare account ID"
}

variable "cloudflare_api_token" {
  type        = string
  description = "API token with Cloudflare Workers permissions"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for your domain"
}

variable "worker_route" {
  type        = string
  description = "e.g., example.com/*"
}

variable "maintenance_title" {
  type        = string
  default     = "We'll be back soon!"
  description = "Maintenance page title"
}

variable "maintenance_message" {
  type        = string
  default     = "Our site is undergoing maintenance. Please check back later."
  description = "Maintenance page message"
}

variable "maintenance_image_url" {
  type        = string
  default     = ""
  description = "Optional hero image for maintenance page"
}
