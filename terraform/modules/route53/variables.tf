variable "domain_name" {
  description = "e.g. vpbmma.com"
  type        = string
}

variable "create_zone" {
  description = "true if Route53 should own the zone (domain bought/transferred into Route53); false to reference an existing zone"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

