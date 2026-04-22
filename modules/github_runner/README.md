# GitHub Runner Module

This module creates a self-hosted GitHub Actions runner on a persistent EC2 instance with SSM access (no SSH key required).

## Features

- **No SSH Key Required**: Uses AWS Systems Manager (SSM) for secure access
- **Persistent Runner**: Survives EC2 stop/start cycles for manual operation
- **Docker Support**: Pre-installed Docker for containerized workflows
- **Flexible Architecture**: Supports both `amd64` and `arm64` instances
- **Ubuntu 24.04 LTS**: Latest Ubuntu Noble with gp3 SSD

## Usage

### Terragrunt Example

```hcl
# terragrunt.hcl
terraform {
  source = "${get_parent_terragrunt_dir()}/modules/github_runner"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  org_name     = "myorg"
  stage_name   = "dev"
  service_name = "github-runner"
  team_name    = "platform"

  vpc_id          = dependency.vpc.outputs.vpc_id
  private_subnets = dependency.vpc.outputs.private_subnets

  # github_owner defaults to "BloclabsHQ"
  github_runner_token  = get_env("GITHUB_RUNNER_TOKEN")
  github_runner_labels = ["self-hosted", "linux", "x64"]

  instance_type = "t3.medium"
  architecture  = "amd64"

  root_volume_size = 50
}
```

### Terraform Example

```hcl
module "github_runner" {
  source = "./modules/github_runner"

  org_name     = "myorg"
  stage_name   = "dev"
  service_name = "github-runner"
  team_name    = "platform"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  # github_owner defaults to "BloclabsHQ"
  github_runner_token  = var.github_runner_token
  github_runner_labels = ["self-hosted", "linux", "x64"]

  instance_type = "t3.medium"
}
```

## Generating GitHub Runner Token

### Organization-level Runner (BloclabsHQ)

```bash
# Using GitHub CLI
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /orgs/BloclabsHQ/actions/runners/registration-token \
  | jq -r '.token'
```

## Accessing the Instance

Since no SSH key is configured, use AWS Systems Manager Session Manager:

```bash
# Using AWS CLI
aws ssm start-session --target <instance-id>

# Using AWS Console
# Navigate to EC2 > Instances > Select Instance > Connect > Session Manager
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| org_name | Organization name for resource naming | `string` | n/a | yes |
| stage_name | Stage/environment name | `string` | n/a | yes |
| service_name | Service name for resource naming | `string` | n/a | yes |
| team_name | Team name tag | `string` | n/a | yes |
| vpc_id | VPC ID where runner will be deployed | `string` | n/a | yes |
| private_subnets | List of private subnet IDs | `list(string)` | n/a | yes |
| github_owner | GitHub organization name | `string` | `"BloclabsHQ"` | no |
| github_runner_token | GitHub runner registration token | `string` | n/a | yes |
| github_runner_labels | Labels for the GitHub runner | `list(string)` | `["self-hosted", "linux"]` | no |
| github_runner_group | Runner group name | `string` | `"default"` | no |
| instance_type | EC2 instance type | `string` | `"t3a.small"` | no |
| architecture | Instance architecture (amd64/arm64) | `string` | `"amd64"` | no |
| root_volume_size | Root volume size in GB | `number` | `50` | no |
| instance_state | Desired EC2 state (running/stopped) | `string` | `"running"` | no |
| use_spot_instance | Use spot instance | `bool` | `true` | no |
| additional_iam_policies | Additional IAM policies | `map(string)` | `{}` | no |
| additional_security_group_rules | Additional SG ingress rules | `list(object)` | `[]` | no |
| runner_version | GitHub runner version | `string` | `"latest"` | no |
| extra_user_data | Extra user data script | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | EC2 instance ID |
| instance_arn | EC2 instance ARN |
| private_ip | Private IP address |
| security_group_id | Security group ID |
| iam_role_name | IAM role name |
| iam_role_arn | IAM role ARN |
| iam_instance_profile_arn | IAM instance profile ARN |

## Notes

- The runner is configured as **persistent**, meaning it will survive EC2 stop/start cycles
- GitHub runner tokens expire after 1 hour, so infrastructure needs to be provisioned within that window
- For production use, consider using AWS Secrets Manager to store the token
- The security group only allows outbound traffic by default; SSM uses outbound HTTPS
