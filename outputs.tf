output "state_bucket" {
  description = "S3 bucket holding every Terragrunt unit state"
  value       = module.tfstate_bucket.s3_bucket_id
}

output "state_kms_key_arn" {
  description = "KMS key encrypting the state bucket"
  value       = module.tfstate_kms.key_arn
}

output "gha_plan_role_arn" {
  description = "Set as GitHub repository variable AWS_PLAN_ROLE_ARN"
  value       = module.gha_plan_role.arn
}

output "gha_lifecycle_role_arn" {
  description = "Set as GitHub environment (lab) variable AWS_LIFECYCLE_ROLE_ARN"
  value       = module.gha_lifecycle_role.arn
}

output "region" {
  description = "Set as GitHub repository variable AWS_REGION"
  value       = var.region
}

output "secrets_kms_key_arn" {
  description = "KMS key encrypting the Secrets Manager entries"
  value       = module.secrets_kms.key_arn
}

output "secret_arns" {
  description = "Secrets Manager ARNs by name, to fill manually"
  value       = { for k, s in aws_secretsmanager_secret.this : k => s.arn }
}
