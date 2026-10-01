env          = "dev"
account_name = "dev-aws-account"
region       = "us-east-1"
github_owner = "Badmamane"
github_repo  = "k8s-ministral-8b-platform"
# ------ Optional: numeric owner and repository IDs select the immutable OIDC subject
# ------ form (repo:owner@id/repo@id:...). Read them with
# ------ `gh api users/<owner> --jq .id` and `gh api repos/<owner>/<repo> --jq .id`.
# github_owner_id  = 0
# github_repo_id   = 0
monthly_budget_usd = 100
budget_alert_email = "budget-alerts@example.com"
secrets = {
  argocd-deploy-key = {
    description = "Placeholder for the Read-only SSH deploy key used by Argo CD to clone the repository. The real value should be stored in AWS Secrets Manager and never in Terraform state or codebase."
  },
  grafana-admin = {
    description = "Grafana admin password. The real value should be stored in AWS Secrets Manager and never in Terraform state or codebase."
  },
  gateway-api-keys = {
    description = "Consumer API keys for the inference gateway, one JSON field per client id. The real value should be stored in AWS Secrets Manager and never in Terraform state or codebase."
  }
}
cloudtrail = {
  log_retention_days    = 90
  include_read_events   = true
  enable_log_validation = true
}
