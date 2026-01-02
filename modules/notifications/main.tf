# Notification module for maintenance windows
# Supports Slack, PagerDuty, and generic webhook notifications

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2, < 4.0"
    }
  }
}

# Parse notification URLs and send notifications
resource "null_resource" "notification" {
  count = length(var.notification_urls)

  triggers = {
    maintenance_status = var.maintenance_status
    schedule_name      = var.schedule_name
    timestamp          = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${local.notification_scripts[count.index]}
    EOT
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # Parse notification URLs and create appropriate curl commands
  notification_scripts = [
    for url in var.notification_urls :
    startswith(url, "slack://") ? local.slack_notification :
    startswith(url, "pagerduty://") ? local.pagerduty_notification :
    startswith(url, "webhook://") ? local.webhook_notification :
    "echo 'Unknown notification type: ${url}'"
  ]

  # Extract webhook URL from slack://webhook_url format
  slack_webhook_url = length([for url in var.notification_urls : url if startswith(url, "slack://")]) > 0 ? replace([for url in var.notification_urls : url if startswith(url, "slack://")][0], "slack://", "https://hooks.slack.com/services/") : ""

  # Extract PagerDuty integration key
  pagerduty_key = length([for url in var.notification_urls : url if startswith(url, "pagerduty://")]) > 0 ? replace([for url in var.notification_urls : url if startswith(url, "pagerduty://")][0], "pagerduty://", "") : ""

  # Extract generic webhook URL
  webhook_url = length([for url in var.notification_urls : url if startswith(url, "webhook://")]) > 0 ? replace([for url in var.notification_urls : url if startswith(url, "webhook://")][0], "webhook://", "") : ""

  # Slack notification using curl
  slack_notification = local.slack_webhook_url != "" ? <<-EOT
    curl -X POST '${local.slack_webhook_url}' \
      -H 'Content-Type: application/json' \
      -d '{
        "text": "🔧 Maintenance ${var.maintenance_status}",
        "blocks": [
          {
            "type": "header",
            "text": {
              "type": "plain_text",
              "text": "Maintenance ${var.maintenance_status}: ${var.schedule_name}"
            }
          },
          {
            "type": "section",
            "fields": [
              {
                "type": "mrkdwn",
                "text": "*Status:*\n${var.maintenance_status}"
              },
              {
                "type": "mrkdwn",
                "text": "*Window:*\n${var.maintenance_window.start_time} - ${var.maintenance_window.end_time}"
              },
              {
                "type": "mrkdwn",
                "text": "*Environment:*\n${var.environment}"
              },
              {
                "type": "mrkdwn",
                "text": "*Schedule:*\n${var.schedule_name}"
              }
            ]
          }
        ]
      }'
  EOT
  : "echo 'No Slack webhook configured'"

  # PagerDuty notification
  pagerduty_notification = local.pagerduty_key != "" ? <<-EOT
    curl -X POST 'https://events.pagerduty.com/v2/enqueue' \
      -H 'Content-Type: application/json' \
      -d '{
        "routing_key": "${local.pagerduty_key}",
        "event_action": "trigger",
        "payload": {
          "summary": "Maintenance ${var.maintenance_status}: ${var.schedule_name}",
          "severity": "warning",
          "source": "terraform-cloudflare-maintenance",
          "custom_details": {
            "status": "${var.maintenance_status}",
            "environment": "${var.environment}",
            "schedule": "${var.schedule_name}",
            "start_time": "${var.maintenance_window.start_time}",
            "end_time": "${var.maintenance_window.end_time}"
          }
        }
      }'
  EOT
  : "echo 'No PagerDuty key configured'"

  # Generic webhook notification
  webhook_notification = local.webhook_url != "" ? <<-EOT
    curl -X POST '${local.webhook_url}' \
      -H 'Content-Type: application/json' \
      -d '{
        "status": "${var.maintenance_status}",
        "schedule_name": "${var.schedule_name}",
        "environment": "${var.environment}",
        "maintenance_window": {
          "start_time": "${var.maintenance_window.start_time}",
          "end_time": "${var.maintenance_window.end_time}"
        }
      }'
  EOT
  : "echo 'No webhook URL configured'"
}
