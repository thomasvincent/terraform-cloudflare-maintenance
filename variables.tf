variable "cloudflare_api_token" {
  description = "Cloudflare API token with least privileges"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, production)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "worker_route" {
  description = "URL pattern to trigger the maintenance worker"
  type        = string
  default     = "*.example.com/*"
}

variable "enabled" {
  description = "Toggle maintenance mode on/off"
  type        = bool
  default     = false
}

variable "maintenance_title" {
  description = "Title for the maintenance page"
  type        = string
  default     = "System Maintenance in Progress"
}

variable "contact_email" {
  description = "Contact email to display on the maintenance page"
  type        = string
  default     = "support@example.com"
}

variable "allowed_ips" {
  description = "List of IP addresses that can bypass the maintenance page"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges in CIDR notation that can bypass the maintenance page"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for cidr in var.allowed_ip_ranges : can(cidrnetmask(cidr))
    ])
    error_message = "All values in allowed_ip_ranges must be valid CIDR notation (e.g., 192.168.1.0/24)."
  }
}

variable "allowed_regions" {
  description = "List of geographical regions that can bypass maintenance mode"
  type        = list(string)
  default     = []
  validation {
    condition = length(var.allowed_regions) == 0 || alltrue([
      for region in var.allowed_regions : contains([
        "APAC", "ENAM", "EU", "SAME", "AF", "NA", "OC", "AS", "EU", "SA"
      ], region)
    ])
    error_message = "All values must be valid Cloudflare region codes."
  }
}

variable "maintenance_window" {
  description = "Scheduled maintenance window in RFC3339 format"
  type = object({
    start_time = string
    end_time   = string
  })
  default = null
  validation {
    condition     = var.maintenance_window == null || (can(parsedate(var.maintenance_window.start_time)) && can(parsedate(var.maintenance_window.end_time)))
    error_message = "Maintenance window times must be valid timestamps (e.g., 2025-04-06T08:00:00Z)."
  }
}

variable "maintenance_language" {
  description = "Default language for the maintenance page"
  type        = string
  default     = "en"
  validation {
    condition     = contains(["en", "es", "fr", "de", "it", "pt", "ja", "zh", "ru"], var.maintenance_language)
    error_message = "Language must be one of the supported language codes: en, es, fr, de, it, pt, ja, zh, ru."
  }
}

variable "custom_css" {
  description = "Custom CSS for the maintenance page"
  type        = string
  default     = ""
}

variable "logo_url" {
  description = "URL to the logo to display on the maintenance page"
  type        = string
  default     = ""
}

variable "rate_limit" {
  description = "Rate limiting configuration using Cloudflare Ruleset Rate Limiting"
  type = object({
    enabled               = bool
    requests_per_period   = number
    period                = number
    action                = string
    mitigation_timeout    = number
    counting_expression   = optional(string)
    requests_to_origin    = optional(bool)
  })
  default = {
    enabled               = false
    requests_per_period   = 100
    period                = 60
    action                = "block"
    mitigation_timeout    = 600
    counting_expression   = null
    requests_to_origin    = false
  }
  validation {
    condition     = contains(["block", "challenge", "js_challenge", "managed_challenge", "log"], var.rate_limit.action)
    error_message = "Rate limit action must be one of: block, challenge, js_challenge, managed_challenge, log."
  }
  validation {
    condition     = var.rate_limit.period >= 10 && var.rate_limit.period <= 86400
    error_message = "Rate limit period must be between 10 and 86400 seconds."
  }
  validation {
    condition     = var.rate_limit.mitigation_timeout >= 60 && var.rate_limit.mitigation_timeout <= 86400
    error_message = "Mitigation timeout must be between 60 and 86400 seconds."
  }
}

variable "api_key" {
  description = "Custom API key for maintenance API (will be generated randomly if not provided)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "create_dns_record" {
  description = "Whether to create a DNS record for the maintenance page"
  type        = bool
  default     = false
}

variable "dns_record_name" {
  description = "DNS record name for the maintenance page"
  type        = string
  default     = "maintenance"
}

variable "create_page_rule" {
  description = "Whether to create a page rule for cache control"
  type        = bool
  default     = false
}
