variable "create" {
  type    = bool
  default = true
}

variable "alb_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "domain_name" {
  type = string
}

variable "redirect_to" {
  type = string
}

variable "create_route53_cname" {
  type    = bool
  default = true
}