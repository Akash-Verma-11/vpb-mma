output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "secrets_manager_arn" {
  description = "Pull DB credentials from here via IRSA at runtime — never hardcode them"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

