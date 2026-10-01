module "secrets_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.2"

  description             = "${var.project} ${var.env} Secrets Manager entries"
  aliases                 = ["${var.project}-${var.env}-secrets"]
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true
}

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name        = "${var.project}-${var.env}/${each.key}"
  description = each.value.description
  kms_key_id  = module.secrets_kms.key_arn

  recovery_window_in_days = var.kms_deletion_window_days
}

resource "aws_secretsmanager_secret_version" "placeholder" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = "PLACEHOLDER"

  lifecycle {
    ignore_changes = [secret_string]
  }
}
