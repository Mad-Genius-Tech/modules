# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"]
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server*"]
#   }
# }

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

locals {
  user_data = {
    region         = data.aws_region.current.name
    secret_id      = reverse(split(":", module.aurora.cluster_master_user_secret[0].secret_arn))[0]
    config_bucket  = module.config_bucket.s3_bucket_id
    db_name        = module.aurora.cluster_database_name
    db_host        = module.aurora.cluster_endpoint
    site_url       = "https://${var.domain_name}"
    wp_title       = var.domain_name
    wp_username    = "admin"
    wp_password    = "admin!@#zxc."
    wp_email       = "sggamecard@gmail.com"
    file_system_id = var.efs_enabled ? module.efs.id : ""
    redis_endpoint = "${aws_elasticache_replication_group.elasticache.primary_endpoint_address}:6379"
  }
}

module "wordpress_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.1"
  name    = "${module.context.id}-ec2"
  vpc_id  = var.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.vpc_cidr_block
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_iam_policy" "ec2_policy" {
  name = "${module.context.id}-ec2"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        Effect = "Allow",
        Resource = [
          module.aurora.cluster_master_user_secret[0].secret_arn
        ]
      },
      {
        Action = [
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
          "elasticfilesystem:ClientMount"
        ],
        Effect = "Allow",
        Resource = [
          var.efs_enabled ? module.efs.arn : "*"
        ]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          module.config_bucket.s3_bucket_arn,
          "${module.config_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "autoscaling:DescribeAutoScalingInstances"
        ],
        Effect = "Allow",
        Resource = [
          "*"
        ]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketOwnershipControls",
          "s3:PutBucketOwnershipControls",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Effect = "Allow",
        Resource = [
          module.wordpress_bucket.s3_bucket_arn,
          "${module.wordpress_bucket.s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "s3:ListAllMyBuckets"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::*"
        ]
      }
    ]
  })
}

module "asg" {
  source                          = "terraform-aws-modules/autoscaling/aws"
  version                         = "7.4.1"
  create                          = var.asg_enabled
  name                            = "${module.context.id}-asg"
  min_size                        = 1
  max_size                        = 4
  desired_capacity                = 1
  ignore_desired_capacity_changes = false
  wait_for_capacity_timeout       = 0
  default_instance_warmup         = 300
  health_check_grace_period       = 180
  health_check_type               = "ELB"
  vpc_zone_identifier             = var.private_subnet_ids

  create_traffic_source_attachment = true
  traffic_source_identifier        = module.alb.target_groups["wordpress"].arn
  traffic_source_type              = "elbv2"

  # Launch template
  launch_template_name   = "${module.context.id}-asg"
  update_default_version = true

  image_id          = data.aws_ami.amazon_linux_2.id
  instance_type     = var.instance_type
  user_data         = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", local.user_data))
  ebs_optimized     = true
  enable_monitoring = false

  create_iam_instance_profile = var.asg_enabled ? true : false
  iam_role_name               = "${module.context.id}-ec2"
  iam_role_tags               = local.tags
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgent              = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    EC2Policy                    = aws_iam_policy.ec2_policy.arn
  }
  network_interfaces = [
    {
      security_groups = [
        module.wordpress_sg.security_group_id
      ]
    }
  ]

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp3"
      }
    }
  ]

  # Mixed instances
  # use_mixed_instances_policy = true
  # mixed_instances_policy = {
  #   instances_distribution = {
  #     on_demand_base_capacity                  = 0
  #     on_demand_percentage_above_base_capacity = 10
  #     spot_allocation_strategy                 = "capacity-optimized"
  #   }
  #   override = [
  #     {
  #       instance_type     = "t3.medium"
  #       weighted_capacity = "2"
  #     },
  #     {
  #       instance_type     = "t3a.medium"
  #       weighted_capacity = "1"
  #     },
  #   ]
  # }

  # instance_market_options = {
  #   market_type = "spot"
  # }

  # Target scaling policy schedule based on average CPU load
  scaling_policies = {
    avg-cpu-policy = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 1200
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 70.0
      }
    }
  }
  tags = local.tags

  depends_on = [
    resource.aws_s3_bucket_object.template,
    resource.aws_s3_bucket_object.config
  ]
}
