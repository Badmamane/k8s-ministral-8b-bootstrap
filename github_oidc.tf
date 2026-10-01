module "github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"
  version = "~> 6.8"

  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "tfstate_access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [module.tfstate_bucket.s3_bucket_arn]
  }

  statement {
    sid = "ReadWriteStateObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject", # ------ S3 native locking creates and removes a .tflock object
    ]
    resources = ["${module.tfstate_bucket.s3_bucket_arn}/*"]
  }

  statement {
    sid = "UseStateKmsKey"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [module.tfstate_kms.key_arn]
  }
}

module "tfstate_access_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 6.8"

  name        = "${var.project}-${var.env}-tfstate-access"
  description = "Read/write Terraform state objects and the S3 lockfile"
  policy      = data.aws_iam_policy_document.tfstate_access.json
}

module "gha_plan_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.8"

  name            = "${var.project}-${var.env}-gha-plan"
  use_name_prefix = false
  description     = "GitHub Actions: terragrunt run --all plan"

  enable_github_oidc = true
  oidc_subjects      = ["${local.repo}:environment:${var.env}"]

  max_session_duration = var.plan_role_max_session_seconds

  policies = {
    ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
    TfstateAccess  = module.tfstate_access_policy.arn
  }

  depends_on = [module.github_oidc_provider]
}

data "aws_iam_policy_document" "gha_lifecycle_iam" {
  statement {
    sid = "ManageProjectIamResources"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
    ]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.project}-${var.env}-*",
      "arn:aws:iam::${local.account_id}:policy/${var.project}-${var.env}-*",
      "arn:aws:iam::${local.account_id}:instance-profile/${var.project}-${var.env}-*",
    ]
  }

  statement {
    sid       = "PassProjectRoles"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.project}-${var.env}-*"]
  }

  statement {
    sid = "ServiceLinkedRolesAndReads"
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:GetRole",
      "iam:ListRoles",
      "iam:ListPolicies",
      "iam:ListOpenIDConnectProviders",
      "iam:GetOpenIDConnectProvider",
    ]
    resources = ["*"]
  }
}

module "gha_lifecycle_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 6.8"

  name        = "${var.project}-${var.env}-gha-lifecycle-iam"
  description = "IAM writes limited to ${var.project}-${var.env}-* resources"
  policy      = data.aws_iam_policy_document.gha_lifecycle_iam.json
}

module "gha_lifecycle_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.8"

  name            = "${var.project}-${var.env}-gha-lifecycle"
  use_name_prefix = false
  description     = "GitHub Actions: terragrunt run --all apply and destroy"

  enable_github_oidc   = true
  oidc_subjects        = ["${local.repo}:environment:${local.deploy_environment}"]
  max_session_duration = var.lifecycle_role_max_session_seconds

  policies = {
    PowerUserAccess = "arn:aws:iam::aws:policy/PowerUserAccess"
    ProjectIam      = module.gha_lifecycle_iam_policy.arn
    TfstateAccess   = module.tfstate_access_policy.arn
  }

  # ------ The bootstrap roles share the project prefix; an explicit deny keeps
  # ------ CI from widening its own permissions.
  create_inline_policy = true
  inline_policy_permissions = {
    DenyBootstrapRoles = {
      effect  = "Deny"
      actions = ["iam:*"]
      resources = [
        "arn:aws:iam::${local.account_id}:role/${var.project}-${var.env}-gha-plan",
        "arn:aws:iam::${local.account_id}:role/${var.project}-${var.env}-gha-lifecycle",
        "arn:aws:iam::${local.account_id}:policy/${var.project}-${var.env}-gha-lifecycle-iam",
        "arn:aws:iam::${local.account_id}:policy/${var.project}-${var.env}-tfstate-access",
      ]
    }
  }

  depends_on = [module.github_oidc_provider]
}
