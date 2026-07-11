output "role_arns" {
  description = "Map of service key => IAM role ARN, to reference in each ServiceAccount's eks.amazonaws.com/role-arn annotation"
  value       = { for k, r in aws_iam_role.service : k => r.arn }
}

