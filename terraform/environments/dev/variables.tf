variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "cluster_name" {
  type    = string
  default = "vpb-mma-dev"
}

variable "domain_name" {
  description = "Your registered domain, e.g. vpbmma.com"
  type        = string
}

variable "create_route53_zone" {
  type    = bool
  default = true
}

