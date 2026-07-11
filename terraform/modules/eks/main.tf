# ==========================================================================
# EKS module — cluster + managed node group + IRSA roles for the
# EBS CSI driver and the AWS Load Balancer Controller.
#
# Lessons baked in from ShopFlow:
#  - Multi instance type node group across all 3 private-subnet AZs
#    (avoids the t3.micro 4-pod kubelet ceiling that caused scheduling
#    failures previously).
#  - EBS CSI driver installed as a managed add-on WITH its IRSA role
#    attached up front (avoids the missing-PVC Jenkins failure).
#  - enable_irsa = true so every workload can get scoped AWS permissions
#    instead of broad node-level IAM.
# ==========================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  enable_irsa                             = true
  cluster_endpoint_public_access          = true
  cluster_endpoint_private_access         = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    default = {
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Multiple instance types + spread across 3 AZs = no repeat of the
      # ShopFlow single-AZ / single-type scheduling deadlock.
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      subnet_ids = var.private_subnet_ids

      labels = {
        role = "app"
      }
    }
  }

  tags = var.tags
}

# ---- IRSA: EBS CSI driver ----
module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name             = "${var.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

# ---- IRSA: AWS Load Balancer Controller ----
module "load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name                              = "${var.cluster_name}-lb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = var.tags
}

# ---- IRSA: Cluster Autoscaler ----
module "cluster_autoscaler_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name                        = "${var.cluster_name}-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = var.tags
}

