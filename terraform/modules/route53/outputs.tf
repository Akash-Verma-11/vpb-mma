output "zone_id" {
  value = local.zone_id
}

output "name_servers" {
  description = "Point your domain registrar's NS records at these"
  value       = var.create_zone ? aws_route53_zone.this[0].name_servers : null
}

output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.this.certificate_arn
}

