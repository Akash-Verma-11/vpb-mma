variable "name" {
  type    = string
  default = "vpb-mma-dev"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_node_security_group_id" {
  description = "Only allow inbound 5432 from EKS nodes, nothing else"
  type        = string
}

variable "engine_version" {
  type    = string
  default = "16.13"
}

variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  description = "Enables storage autoscaling up to this size (GB)"
  type        = number
  default     = 100
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "db_name" {
  type    = string
  default = "vpbmma"
}

variable "master_username" {
  type    = string
  default = "vpbmma_admin"
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "skip_final_snapshot" {
  description = "Set false for anything you'd call production"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

