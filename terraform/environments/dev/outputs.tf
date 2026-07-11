output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Run this after apply to connect kubectl to the new cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "db_secret_arn" {
  value = module.rds.secrets_manager_arn
}

# commenting out b/c domain is not registered
#output "route53_name_servers" {
#  description = "Point your domain registrar at these if create_route53_zone = true"
#  value       = module.route53.name_servers
#}

#output "acm_certificate_arn" {
#  value = module.route53.acm_certificate_arn
#}

output "load_balancer_controller_role_arn" {
  value = module.eks.load_balancer_controller_role_arn
}

output "cluster_autoscaler_role_arn" {
  value = module.eks.cluster_autoscaler_role_arn
}

output "service_irsa_role_arns" {
  value = module.iam.role_arns
}

