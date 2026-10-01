data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid       = "AWSCloudTrailAclCheck"
    actions   = ["s3:GetBucketAcl"]
    resources = [module.cloudtrail_bucket.s3_bucket_arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region}:${local.account_id}:trail/${local.name}"]
    }
  }

  statement {
    sid       = "AWSCloudTrailWrite"
    actions   = ["s3:PutObject"]
    resources = ["${module.cloudtrail_bucket.s3_bucket_arn}/AWSLogs/${local.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.region}:${local.account_id}:trail/${local.name}"]
    }
  }
}

locals {
  name         = "${var.project}-${var.env}"
  account_id   = data.aws_caller_identity.current.account_id
  state_bucket = "${var.project}-${var.env}-tfstate-${local.account_id}"
  # ------ GitHub immutable OIDC subjects carry the owner and repository IDs, so a
  # ------ repository deleted and re-created under the same name cannot assume the roles.
  repo = (
    var.github_owner_id != null && var.github_repo_id != null
    ? "${var.github_owner}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}"
    : "${var.github_owner}/${var.github_repo}"
  )
  deploy_environment = "${var.env}-deploy"
}
