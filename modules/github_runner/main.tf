locals {
  identifier = "${module.context.id}-ec2"

  default_iam_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  runner_url = "https://github.com/${var.github_owner}"

  user_data = <<-EOF
#!/bin/bash
set -ex

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y git docker.io jq ca-certificates wget curl zip unzip tar gzip yq docker-compose

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Start and enable docker
systemctl start docker
systemctl enable docker

# Create runner user
useradd -m -s /bin/bash runner
usermod -aG docker runner

# Create runner directory
mkdir -p /home/runner/actions-runner
cd /home/runner/actions-runner

# Build unique runner name using instance ID (IMDSv2)
IMDS_TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)
if [ -n "$IMDS_TOKEN" ]; then
  INSTANCE_ID=$(curl -sH "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
    http://169.254.169.254/latest/meta-data/instance-id || true)
fi
if [ -z "$INSTANCE_ID" ]; then
  INSTANCE_ID="unknown"
fi
RUNNER_NAME="${local.identifier}-$INSTANCE_ID"

# Determine architecture
ARCH="${var.architecture == "amd64" ? "x64" : "arm64"}"

# Get latest runner version or use specified version
if [ "${var.runner_version}" == "latest" ]; then
  RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
else
  RUNNER_VERSION="${var.runner_version}"
fi

# Download and extract runner
curl -o actions-runner-linux-$ARCH-$RUNNER_VERSION.tar.gz -L \
  https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-$ARCH-$RUNNER_VERSION.tar.gz
tar xzf ./actions-runner-linux-$ARCH-$RUNNER_VERSION.tar.gz
rm -f ./actions-runner-linux-$ARCH-$RUNNER_VERSION.tar.gz

# Set ownership
chown -R runner:runner /home/runner/actions-runner

# Configure runner as runner user (persistent runner for manual stop/start)
su - runner -c "cd /home/runner/actions-runner && ./config.sh --url ${local.runner_url} --token ${var.github_runner_token} --name $RUNNER_NAME --labels ${join(",", var.github_runner_labels)} --runnergroup ${var.github_runner_group} --unattended --replace"

# Install and start as service
./svc.sh install runner
./svc.sh start

# Ensure runner service starts on boot
systemctl enable actions.runner.${var.github_owner}.$RUNNER_NAME.service

${var.extra_user_data}
EOF
}

resource "random_shuffle" "private_subnet" {
  input = var.private_subnets
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "architecture"
    values = var.architecture == "amd64" ? ["x86_64"] : ["arm64"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-*-server-*"]
  }
}

module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 6.2.0"

  name          = local.identifier
  instance_type = var.instance_type
  ami           = data.aws_ami.ubuntu.id

  subnet_id                   = random_shuffle.private_subnet.result[0]
  associate_public_ip_address = false
  vpc_security_group_ids      = [module.sg.security_group_id]

  # Spot instance configuration
  create_spot_instance                = var.use_spot_instance
  spot_type                           = var.use_spot_instance ? "persistent" : null
  spot_wait_for_fulfillment           = var.use_spot_instance ? true : null
  spot_instance_interruption_behavior = var.use_spot_instance ? "stop" : null

  # IAM instance profile for SSM
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for GitHub Runner ${local.identifier}"
  iam_role_policies           = merge(local.default_iam_policies, var.additional_iam_policies)

  # User data for runner installation
  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true

  # Root volume
  root_block_device = {
    encrypted             = true
    delete_on_termination = true
    size                  = var.root_volume_size
    type                  = "gp3"
  }

  # Instance settings
  disable_api_stop        = false
  disable_api_termination = false

  tags = local.tags
}

module "sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.1.2"

  name        = local.identifier
  description = "Security group for GitHub Runner ${local.identifier}"
  vpc_id      = var.vpc_id

  # Only outbound traffic needed for GitHub runner
  # SSM uses outbound HTTPS connections
  ingress_with_cidr_blocks = var.additional_security_group_rules

  egress_rules = ["all-all"]

  tags = local.tags
}

# Control EC2 instance state (running/stopped)
# Note: For spot instances with persistent type, you can still stop/start
resource "aws_ec2_instance_state" "this" {
  instance_id = module.ec2.id
  state       = var.instance_state
}
