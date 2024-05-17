

module "ec2" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "~> 5.6.1"
  create                      = var.asg_enabled ? false : true
  name                        = "${module.context.id}-ec2"
  instance_type               = var.instance_type
  ami                         = data.aws_ami.amazon_linux_2.id
  ignore_ami_changes          = true
  subnet_id                   = var.private_subnet_ids[0]
  associate_public_ip_address = false
  disable_api_stop            = false
  disable_api_termination     = true
  create_iam_instance_profile = true
  iam_role_name               = "${module.context.id}-ec2"
  iam_role_description        = "IAM role for EC2 ${module.context.id}-ec2"
  iam_role_tags               = local.tags
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgent              = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    EC2Policy                    = aws_iam_policy.ec2_policy.arn
  }
  user_data                   = base64encode(templatefile("${path.module}/scripts/bootstrap.sh", local.user_data))
  user_data_replace_on_change = false
  root_block_device = [
    {
      device_name = "/dev/xvda"
      encrypted   = true
      volume_type = "gp3"
      volume_size = 20
    },
  ]
  ebs_block_device = [
    {
      device_name           = "/dev/sdb"
      encrypted             = true
      volume_type           = "gp3"
      volume_size           = 100
      delete_on_termination = false
    }
  ]
  vpc_security_group_ids = [module.wordpress_sg.security_group_id]
  monitoring             = false
  tags                   = local.tags

  depends_on = [
    resource.aws_s3_bucket_object.template,
    resource.aws_s3_bucket_object.config
  ]
}
