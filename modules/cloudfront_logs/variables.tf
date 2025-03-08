
variable "s3_bucket" {
  type        = string
  description = "The name of the S3 bucket that is used to store the CloudFront access logs"
  default     = ""
}

variable "resource_prefix" {
  type        = string
  default     = "myapp"
  description = "Prefix that is used for the created resources (20 chars, a-z and 0-9 only)"
  validation {
    condition     = can(regex("^[a-z0-9]{1,20}$", var.resource_prefix))
    error_message = "The resource_prefix must be 1-20 characters long and contain only lowercase letters and numbers."
  }
}

variable "new_key_prefix" {
  type        = string
  default     = "new/"
  description = "Prefix of new access log files that are written by Amazon CloudFront. Including the trailing slash."
  validation {
    condition     = can(regex("^[A-Za-z0-9\\-]+/$", var.new_key_prefix))
    error_message = "The new_key_prefix must end with a slash and contain only letters, numbers, and hyphens."
  }
}

variable "gz_key_prefix" {
  type        = string
  default     = "partitioned-gz/"
  description = "Prefix of gzip'ed access log files that are moved to the Apache Hive like style. Including the trailing slash."
  validation {
    condition     = can(regex("^[A-Za-z0-9\\-]+/$", var.gz_key_prefix))
    error_message = "The gz_key_prefix must end with a slash and contain only letters, numbers, and hyphens."
  }
}

variable "parquet_key_prefix" {
  type        = string
  default     = "partitioned-parquet/"
  description = "Prefix of parquet files that are created in Apache Hive like style by the CTAS query. Including the trailing slash."
  validation {
    condition     = can(regex("^[A-Za-z0-9\\-]+/$", var.parquet_key_prefix))
    error_message = "The parquet_key_prefix must end with a slash and contain only letters, numbers, and hyphens."
  }
}
