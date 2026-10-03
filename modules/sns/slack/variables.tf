variable "create" {
  type = bool
}

variable "lambda_function_name" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "webhook_url" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
}
