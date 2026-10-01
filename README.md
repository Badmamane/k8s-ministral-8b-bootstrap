# k8s-ministral-8b-bootstrap

One-time, per-AWS-account stack for
[k8s-ministral-8b-platform](https://github.com/Badmamane/k8s-ministral-8b-platform):
everything the platform's CI needs to exist *before* it can run its first plan.

The platform repository is ephemeral by construction: a GitHub Actions workflow
creates the whole environment, tests it and destroys it. This repository holds
the few resources that must survive those cycles.

## What it creates

| Resource | Purpose |
|---|---|
| S3 bucket `<project>-<env>-tfstate-<account>` + KMS key | Terragrunt remote state, versioned, SSE-KMS, S3 native locking |
| GitHub OIDC provider | Lets GitHub Actions assume IAM roles without long-lived keys |
| IAM role `<project>-<env>-gha-plan` | `ReadOnlyAccess` + state access; assumed by the `ci` workflow from GitHub environment `dev` |
| IAM role `<project>-<env>-gha-lifecycle` | `PowerUserAccess` + IAM writes limited to `<project>-<env>-*` resources, with an explicit deny on the bootstrap roles so CI cannot widen its own permissions; assumed from GitHub environment `dev-deploy` |
| Secrets Manager entries + KMS key | Placeholders for the values the platform reads at runtime; the real values are entered by hand and never stored in Terraform state or Git |
| AWS Budget | Forecast and actual alerts to one email address |
| CloudTrail + S3 bucket + KMS key | Account-wide audit trail, log validation on |

Bootstrap uses **local state on purpose**: it creates the bucket every other
stack stores its state in. `state/` is git-ignored; back the file up after the
first apply.

## OIDC trust

Both roles trust `token.actions.githubusercontent.com` with a subject bound to
one repository and one GitHub environment:

```
repo:<owner>/<repo>:environment:dev          -> gha-plan
repo:<owner>/<repo>:environment:dev-deploy   -> gha-lifecycle
```

Setting `github_owner_id` and `github_repo_id` switches to the immutable subject
form `repo:<owner>@<id>/<repo>@<id>:...`, so a repository deleted and re-created
under the same name cannot assume the roles.

## Usage

```bash
mise install
$EDITOR accounts/dev.tfvars        # account name, region, budget email, GitHub owner/repo
make plan ENV=dev
CREATE=1 make apply ENV=dev
make output ENV=dev
```

Then configure the platform repository on GitHub:

| Where | Name | Value |
|---|---|---|
| Repository variable | `ENV` | `dev` |
| Repository variable | `AWS_REGION` | output `region` |
| Repository variable | `AWS_PLAN_ROLE_ARN` | output `gha_plan_role_arn` |
| Repository variable | `AWS_LIFECYCLE_ROLE_ARN` | output `gha_lifecycle_role_arn` |
| Environment | `dev` | no protection rules; used by the read-only plan |
| Environment | `dev-deploy` | required reviewers recommended; used by apply and destroy |

Finally, replace the secret placeholders. Their names are listed in output
`secret_arns`:

```bash
aws secretsmanager put-secret-value --secret-id k8s-ministral-8b-dev/grafana-admin \
  --secret-string "$(openssl rand -base64 24)"
aws secretsmanager put-secret-value --secret-id k8s-ministral-8b-dev/gateway-api-keys \
  --secret-string '{"client-a": "<api-key>"}'
# argocd-deploy-key is only needed when the platform repository is private
```

## Cost

Three KMS keys, one CloudTrail trail and a few kilobytes of S3: about 4 USD per
month, independent of whether the platform is up.

## Tooling

`mise` pins every tool (`.tool-versions`); `pre-commit` runs `terraform fmt`,
`terraform validate`, `tflint` and secret detection; `checkov` scans the stack;
Renovate keeps providers, modules and actions current. The `ci` workflow runs
the same checks without any cloud credentials.
