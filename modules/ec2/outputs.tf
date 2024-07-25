
output "ec2_info" {
  value = {
    for k, v in module.ec2 : k => {
      instance_id                = v.id
      instance_public_ip         = v.public_ip
      instance_private_ip        = v.private_ip
      instance_public_dns        = v.public_dns
      instance_private_dns       = v.private_dns
      instance_ami               = v.ami
      instance_security_group_id = module.sg[k].security_group_id
      instance_key_name          = local.ec2_map[k].key_name == "" ? aws_key_pair.key_pair_per_instance[k].key_name : local.ec2_map[k].key_name
    }
  }
}