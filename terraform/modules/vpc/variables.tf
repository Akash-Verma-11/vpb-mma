variable "name" {
  description = "Name prefix for the VPC and related resources"
  type        = string
  default     = "vpb-mma-dev"
}

variable "cluster_name" {
  description = "EKS cluster name — used in subnet discovery tags"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across (use 3 for real resilience)"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "single_nat_gateway" {
  description = "true = 1 shared NAT gateway (cheaper); false = 1 per AZ (more resilient, costs more)"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

