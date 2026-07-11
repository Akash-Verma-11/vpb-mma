variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding RDS credentials"
  type        = string
}

variable "service_accounts" {
  description = "Map of microservice key => { namespace, name } for its Kubernetes ServiceAccount"
  type = map(object({
    namespace = string
    name      = string
  }))
  default = {
    catalog-service  = { namespace = "vpb-mma", name = "catalog-service" }
    customer-service = { namespace = "vpb-mma", name = "customer-service" }
    order-service    = { namespace = "vpb-mma", name = "order-service" }
    web-frontend     = { namespace = "vpb-mma", name = "web-frontend" }
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

