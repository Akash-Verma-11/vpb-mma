variable "cluster_name" {
  type    = string
  default = "shopflow-mma-dev"
}

variable "cluster_version" {
  description = "Kubernetes version — pin explicitly, don't float on 'latest'"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_instance_types" {
  description = "Multiple types so the node group isn't blocked by single-type capacity limits"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 6
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "tags" {
  type    = map(string)
  default = {}
}

