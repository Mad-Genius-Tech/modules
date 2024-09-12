variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "available_zone_names" {
  description = "The names of the availability zones"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "The IDs of the public subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets"
  type        = list(string)
}

variable "private_subnets_cidr_blocks" {
  description = "The CIDR blocks of the private subnets"
  type        = list(string)
}

variable "instance_type" {
  description = "The type of the instance"
  type        = string
  default     = "t2a.micro"
}

variable "database_master_username" {
  description = "The master username of the database"
  type        = string
  default     = null
}

variable "database_name" {
  description = "The name of the database"
  type        = string
  default     = null
}

variable "database_engine_version" {
  description = "The version of the database engine"
  type        = string
  default     = null
}

variable "database_min_capacity" {
  description = "The minimum capacity of the database"
  type        = number
  default     = null
}

variable "database_max_capacity" {
  description = "The maximum capacity of the database"
  type        = number
  default     = null
}

variable "database_monitoring_interval" {
  description = "The interval at which to monitor the database"
  type        = number
  default     = null
}

variable "database_performance_insights_enabled" {
  description = "Whether to enable performance insights for the database"
  type        = bool
  default     = null
}

variable "database_performance_insights_retention_period" {
  description = "The retention period for performance insights for the database"
  type        = number
  default     = null
}

variable "database_backup_retention_period" {
  description = "The retention period for backups of the database"
  type        = number
  default     = null
}

variable "efs_enabled" {
  description = "Whether to enable the EFS"
  type        = bool
  default     = false
}

variable "efs_performance_mode" {
  description = "The performance mode of the EFS"
  type        = string
  default     = null
}

variable "efs_throughput_mode" {
  description = "The throughput mode of the EFS"
  type        = string
  default     = null
}

variable "wildcard_domain" {
  description = "Whether to use a wildcard domain"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "The domain name"
  type        = string
  default     = ""
}

variable "attach_ssl" {
  description = "Whether to attach an SSL certificate"
  type        = bool
  default     = true
}

variable "asg_enabled" {
  description = "Whether to enable the ASG"
  type        = bool
  default     = false
}