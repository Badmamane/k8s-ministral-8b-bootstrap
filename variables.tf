variable "env" {
  description = "Environment name; one AWS account per environment (dev, stg, prd). Also the GitHub Actions environment allowed to assume the lifecycle role"
  type        = string
}

variable "account_name" {
  description = "Human name of the AWS account hosting this environment, used for tagging"
  type        = string
}

variable "project" {
  description = "Project slug, used as prefix for every resource name and as the Project tag"
  type        = string
  default     = "k8s-ministral-8b"
}

variable "region" {
  description = "AWS region for the state bucket and the lab"
  type        = string
  default     = "eu-west-1"
}

variable "github_owner" {
  description = "GitHub user or organisation that owns the platform repository"
  type        = string
}

variable "github_repo" {
  description = "Name of the platform repository (without owner) whose workflows may assume the roles"
  type        = string
  default     = "k8s-ministral-8b-platform"
}

variable "github_owner_id" {
  description = "Numeric ID of the GitHub owner; with github_repo_id, selects the immutable OIDC subject form (repo:owner@id/repo@id:...)"
  type        = number
  default     = null
}

variable "github_repo_id" {
  description = "Numeric ID of the GitHub repository; see github_owner_id"
  type        = number
  default     = null
}

variable "kms_deletion_window_days" {
  description = "Waiting period before a scheduled KMS key deletion becomes effective"
  type        = number
  default     = 7
}

variable "state_noncurrent_version_expiration_days" {
  description = "Days before non-current state object versions are expired"
  type        = number
  default     = 90
}

variable "plan_role_max_session_seconds" {
  description = "Maximum STS session duration for the plan role"
  type        = number
  default     = 3600
}

variable "lifecycle_role_max_session_seconds" {
  description = "Maximum STS session duration for the apply/destroy role"
  type        = number
  default     = 7200
}

variable "monthly_budget_usd" {
  description = "Monthly cost budget for the whole account"
  type        = number
  default     = 100
}

variable "budget_forecast_threshold_percent" {
  description = "Forecasted spend percentage that triggers the early alert"
  type        = number
  default     = 80
}

variable "budget_actual_threshold_percent" {
  description = "Actual spend percentage that triggers the hard alert"
  type        = number
  default     = 100
}

variable "budget_alert_email" {
  description = "Email address receiving budget alerts"
  type        = string
}

variable "secrets" {
  description = "Secrets Manager entries created with a placeholder value; real values should never be stored in Terraform state or codebase"
  type = map(object({
    description = string
  }))
}

variable "cloudtrail" {
  description = "Account-wide CloudTrail settings"
  type = object({
    log_retention_days    = number
    include_read_events   = bool
    enable_log_validation = bool
  })
}
