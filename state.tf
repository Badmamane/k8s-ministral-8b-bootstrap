# ------ KMS key for state encryption ------------------------------------------

module "tfstate_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.2"

  description             = "${var.project} Terraform state encryption"
  aliases                 = ["${var.project}-${var.env}-tfstate"]
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true
}

# ------ TERRAFORM state bucket -----------------------------------------------

module "tfstate_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.15"

  bucket = local.state_bucket

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.tfstate_kms.key_arn
      }
      bucket_key_enabled = true
    }
  }

  lifecycle_rule = [{
    id      = "expire-old-versions"
    enabled = true
    filter  = {}
    noncurrent_version_expiration = {
      days = var.state_noncurrent_version_expiration_days
    }
  }]
}
