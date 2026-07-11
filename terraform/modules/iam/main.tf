# ==========================================================================
# IAM module — one IRSA role per microservice that needs AWS access.
# For VPB-MMA v1, every service needs read access to the RDS credentials
# secret. Extend `service_accounts` if a service later needs S3 (product
# images), SES (order emails), etc.
# ==========================================================================

data "aws_iam_policy_document" "assume_role" {
  for_each = var.service_accounts

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "/^.*oidc-provider//", "")}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "/^.*oidc-provider//", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "service" {
  for_each           = var.service_accounts
  name               = "${var.cluster_name}-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json
  tags               = var.tags
}

data "aws_iam_policy_document" "read_db_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }
}

resource "aws_iam_policy" "read_db_secret" {
  name   = "${var.cluster_name}-read-db-secret"
  policy = data.aws_iam_policy_document.read_db_secret.json
}

resource "aws_iam_role_policy_attachment" "read_db_secret" {
  for_each   = var.service_accounts
  role       = aws_iam_role.service[each.key].name
  policy_arn = aws_iam_policy.read_db_secret.arn
}

