module "cloudtrail_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.2"

  description             = "${var.project} ${var.env} CloudTrail logs"
  aliases                 = ["${var.project}-${var.env}-cloudtrail"]
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true

  key_statements = [
    {
      sid       = "AllowCloudTrailEncrypt"
      actions   = ["kms:GenerateDataKey*"]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }]
      conditions = [{
        test     = "StringLike"
        variable = "kms:EncryptionContext:aws:cloudtrail:arn"
        values   = ["arn:aws:cloudtrail:*:${local.account_id}:trail/*"]
      }]
    },
    {
      sid       = "AllowCloudTrailDescribe"
      actions   = ["kms:DescribeKey"]
      resources = ["*"]
      principals = [{
        type        = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }]
    },
  ]
}

module "cloudtrail_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.15"

  bucket = "${local.name}-cloudtrail-${local.account_id}"

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.cloudtrail_bucket.json
  attach_deny_insecure_transport_policy = true

  versioning = {
    enabled = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.cloudtrail_kms.key_arn
      }
      bucket_key_enabled = true
    }
  }

  lifecycle_rule = [{
    id      = "expire-logs"
    enabled = true
    filter  = {}
    expiration = {
      days = var.cloudtrail.log_retention_days
    }
  }]
}

resource "aws_cloudtrail" "this" {
  name                          = local.name
  s3_bucket_name                = module.cloudtrail_bucket.s3_bucket_id
  kms_key_id                    = module.cloudtrail_kms.key_arn
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = var.cloudtrail.enable_log_validation

  event_selector {
    read_write_type           = var.cloudtrail.include_read_events ? "All" : "WriteOnly"
    include_management_events = true
  }

  depends_on = [module.cloudtrail_bucket]
}
