locals {
  common_tags = {
    Project     = "vpb-mma"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

