# CLAUDE.md

Enterprise maintenance mode solution using Cloudflare Workers with scheduling, IP allowlisting, and analytics.

## Stack
- OpenTofu >= 1.6.0
- Cloudflare Provider >= 5.2

## Workflow

```bash
tofu fmt -check
tofu validate
tofu plan

# Worker testing
cd worker && npm test
```

## Notable Capabilities
- Cron-based maintenance window scheduling with timezone support
- Geo-based routing for region-specific maintenance
- Zero-downtime toggle via worker route activation
- Notification integrations (Slack, PagerDuty, webhooks)
- Custom branding with CSS and logo injection
