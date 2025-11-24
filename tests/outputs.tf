# Expose module outputs for testing

output "worker_script_name" {
  description = "Deployed Cloudflare Worker script name"
  value       = module.maintenance.worker_script_name
}

output "worker_route_pattern" {
  description = "Cloudflare route pattern for the maintenance page"
  value       = module.maintenance.worker_route_pattern
}

output "maintenance_status" {
  description = "Current status of the maintenance mode"
  value       = module.maintenance.maintenance_status
}

output "maintenance_page_url" {
  description = "URL to access the maintenance page directly"
  value       = module.maintenance.maintenance_page_url
}

output "dns_record_id" {
  description = "ID of the maintenance page DNS record (if enabled)"
  value       = module.maintenance.dns_record_id
}

output "allowed_ips" {
  description = "IPs allowed to bypass the maintenance page"
  value       = module.maintenance.allowed_ips
  sensitive   = true
}

output "allowed_ip_ranges" {
  description = "IP ranges allowed to bypass the maintenance page"
  value       = module.maintenance.allowed_ip_ranges
  sensitive   = true
}

output "allowed_regions" {
  description = "Geographical regions allowed to bypass the maintenance page"
  value       = module.maintenance.allowed_regions
}

output "maintenance_window" {
  description = "Scheduled maintenance window if configured"
  value       = module.maintenance.maintenance_window
}

output "environment" {
  description = "Current deployment environment"
  value       = module.maintenance.environment
}

output "ruleset_id" {
  description = "ID of the ruleset for bypass configuration (if enabled)"
  value       = module.maintenance.ruleset_id
}

output "rate_limit_id" {
  description = "ID of the rate limit rule (if enabled) - temporarily disabled"
  value       = module.maintenance.rate_limit_id
}

output "api_endpoint" {
  description = "API endpoint for managing maintenance mode"
  value       = module.maintenance.api_endpoint
}

output "api_key" {
  description = "API key for managing maintenance mode"
  value       = module.maintenance.api_key
  sensitive   = true
}
