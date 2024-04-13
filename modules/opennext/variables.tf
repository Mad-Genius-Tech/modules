variable "domain_names" {
  type = list(string)
}

variable "enable_dynamodb_cache" {
  type    = bool
  default = true
}

variable "wildcard_domain" {
  type    = bool
  default = true
}

variable "server_environment_variables" {
  type    = map(string)
  default = {}
}

variable "policy_statements" {
  type = map(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = {}
}

variable "server_cloudwatch_log_retention_in_days" {
  type    = number
  default = null
}

variable "server_memory_size" {
  type    = number
  default = null
}

variable "image_optimisation_memory_size" {
  type    = number
  default = null
}

variable "server_reserved_concurrent_executions" {
  type    = number
  default = null
}

variable "image_reserved_concurrent_executions" {
  type    = number
  default = null
}

variable "schedule_expression" {
  type    = string
  default = null
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_ids" {
  type    = list(any)
  default = []
}

variable "secret_vars" {
  type = map(object({
    secret_path = string
    property    = string
  }))
  default = {}
}

variable "image_optimisation_s3_bucket_arns" {
  type    = list(string)
  default = []
}

variable "discord_url" {
  type    = string
  default = ""
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "sns_topic_arn" {
  type    = string
  default = ""
}