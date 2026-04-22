variable "vpc_id" {
  type        = string
  description = "VPC ID where the runner will be deployed"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for the runner instance"
}

variable "github_owner" {
  type        = string
  default     = "BloclabsHQ"
  description = "GitHub organization name"
}

variable "github_runner_token" {
  type        = string
  sensitive   = true
  description = "GitHub runner registration token"
}

variable "github_runner_labels" {
  type        = list(string)
  default     = ["self-hosted", "linux"]
  description = "Labels for the GitHub runner"
}

variable "github_runner_group" {
  type        = string
  default     = "default"
  description = "Runner group for the GitHub runner"
}

variable "instance_type" {
  type        = string
  default     = "t3a.small"
  description = "EC2 instance type for the runner"
}

variable "architecture" {
  type        = string
  default     = "amd64"
  description = "Architecture of the runner instance (amd64 or arm64)"
  validation {
    condition     = contains(["amd64", "arm64"], var.architecture)
    error_message = "Architecture must be either 'amd64' or 'arm64'."
  }
}

variable "root_volume_size" {
  type        = number
  default     = 50
  description = "Root volume size in GB"
}

variable "additional_iam_policies" {
  type        = map(string)
  default     = {}
  description = "Additional IAM policies to attach to the runner role"
}

variable "additional_security_group_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    description = optional(string)
    cidr_blocks = string
  }))
  default     = []
  description = "Additional security group ingress rules"
}

variable "runner_version" {
  type        = string
  default     = "latest"
  description = "GitHub runner version to install (or 'latest')"
}

variable "extra_user_data" {
  type        = string
  default     = ""
  description = "Extra user data script to append after runner installation"
}

variable "instance_state" {
  type        = string
  default     = "running"
  description = "Desired state of the EC2 instance: 'running' or 'stopped'"
  validation {
    condition     = contains(["running", "stopped"], var.instance_state)
    error_message = "Instance state must be either 'running' or 'stopped'."
  }
}

variable "use_spot_instance" {
  type        = bool
  default     = true
  description = "Use spot instance instead of on-demand (cost savings ~70%)"
}
