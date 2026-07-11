# ==========================================================================
# VPB-MMA — dev environment
# Wires together: vpc -> eks -> rds -> route53 -> iam (IRSA per service)
# Apply order matters on first run; see docs/terraform-guide.md.
# ==========================================================================

module "vpc" {
  source = "../../modules/vpc"

  name         = "${var.cluster_name}-vpc"
  cluster_name = var.cluster_name
  tags         = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name        = var.cluster_name
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  tags                = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name                        = "${var.cluster_name}-db"
  vpc_id                      = module.vpc.vpc_id
  private_subnet_ids          = module.vpc.private_subnet_ids
  eks_node_security_group_id  = module.eks.node_security_group_id
  tags                        = local.common_tags
}

#commenting out b/c domain name is not registered yet
#module "route53" {
#  source = "../../modules/route53"
#  domain_name = var.domain_name
#  create_zone = var.create_route53_zone
#  tags        = local.common_tags
#}

module "iam" {
  source = "../../modules/iam"

  cluster_name       = var.cluster_name
  oidc_provider_arn  = module.eks.oidc_provider_arn
  db_secret_arn      = module.rds.secrets_manager_arn
  tags               = local.common_tags
}

