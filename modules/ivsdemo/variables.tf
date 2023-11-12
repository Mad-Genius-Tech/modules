variable "create" {
  type    = bool
  default = true
}

variable "allow_origins" {
  type    = list(string)
  default = ["*"]
}