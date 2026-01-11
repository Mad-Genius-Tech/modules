locals {
  msk_secrets = merge([
    for k, v in local.msk_map : {
      for sk, sv in v.msk_secrets : "${k}|${sk}" => merge(
        {
          cluster_key  = k
          cluster_name = v.identifier
          secret_key   = sk
        },
        sv
      )
    } if v.create && v.create_scram_secret_association

  ]...)
}

resource "aws_kms_key" "kms" {
  description         = "KMS CMK for ${module.context.id}"
  enable_key_rotation = true
}

resource "aws_secretsmanager_secret" "secrets" {
  for_each    = local.msk_secrets
  name        = "AmazonMSK_${each.value.cluster_name}_${each.value.secret_key}"
  description = lookup(each.value, "description", "Secret for ${each.value.cluster_name} - ${each.value.secret_key}")
  kms_key_id  = aws_kms_key.kms.key_id
  tags        = local.tags
}

resource "random_string" "random" {
  for_each = local.msk_secrets
  length   = 14
  special  = false
  upper    = false
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  for_each  = local.msk_secrets
  secret_id = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = jsonencode({
    username = lookup(each.value, "username", null) != null ? each.value.username : each.value.secret_key
    password = lookup(each.value, "password", null) != null ? each.value.password : random_string.random[each.key].result
  })
}

resource "aws_secretsmanager_secret_policy" "secret_policy" {
  for_each   = local.msk_secrets
  secret_arn = aws_secretsmanager_secret.secrets[each.key].arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSKafkaResourcePolicy"
        Effect = "Allow"
        Principal = {
          Service = "kafka.amazonaws.com"
        }
        Action   = "secretsmanager:getSecretValue"
        Resource = aws_secretsmanager_secret.secrets[each.key].arn
      }
    ]
  })
}

locals {
  acl_command = { for k, v in local.msk_secrets : k => merge(v, { command = join("\n", concat(
    ["source ./utils/commands/load-env.sh \"${var.aws_profile}\" \"${module.msk_kafka_cluster[v.cluster_key].bootstrap_brokers_sasl_iam}\""],
    [
      for access in v.accesses : access.mode == "producer" ?
      "AWS_PROFILE=$AWS_PROFILE kafka-acls.sh --bootstrap-server \"${module.msk_kafka_cluster[v.cluster_key].bootstrap_brokers_sasl_iam}\" --command-config ./utils/client-configs/iam.properties  --add --allow-principal \"User:${v.username}\" --producer --topic \"${access.topics_prefix}\" --resource-pattern-type prefixed" :
      join("\n", [
        "AWS_PROFILE=$AWS_PROFILE kafka-acls.sh --bootstrap-server \"${module.msk_kafka_cluster[v.cluster_key].bootstrap_brokers_sasl_iam}\" --command-config ./utils/client-configs/iam.properties --add --allow-principal \"User:${v.username}\" --consumer --group * --topic \"${access.topics_prefix}\" --resource-pattern-type prefixed",
        "AWS_PROFILE=$AWS_PROFILE kafka-acls.sh --bootstrap-server \"${module.msk_kafka_cluster[v.cluster_key].bootstrap_brokers_sasl_iam}\" --command-config ./utils/client-configs/iam.properties --add --allow-principal \"User:${v.username}\" --operation READ --topic \"${access.topics_prefix}\" --resource-pattern-type prefixed",
        "AWS_PROFILE=$AWS_PROFILE kafka-acls.sh --bootstrap-server \"${module.msk_kafka_cluster[v.cluster_key].bootstrap_brokers_sasl_iam}\" --command-config ./utils/client-configs/iam.properties --add --allow-principal \"User:${v.username}\" --operation DESCRIBE --topic \"${access.topics_prefix}\" --resource-pattern-type prefixed",
        "AWS_PROFILE=$AWS_PROFILE kafka-acls.sh --bootstrap-server \"${module.msk_kafka_cluster[v.cluster_key].bootstrap_brokers_sasl_iam}\" --command-config ./utils/client-configs/iam.properties --add --allow-principal \"User:${v.username}\" --operation READ --group \"*\" --resource-pattern-type literal"
      ])
    ],
    [
      for access in v.accesses :
      "AWS_PROFILE=$AWS_PROFILE kafka-acls.sh --bootstrap-server \"${module.msk_kafka_cluster[v.cluster_key].bootstrap_brokers_sasl_iam}\" --command-config ./utils/client-configs/iam.properties --add --allow-principal \"User:${v.username}\" --operation DescribeConfigs --topic \"${access.topics_prefix}\" --resource-pattern-type prefixed"
    ]
  )) }) if length(v.accesses) > 0 }
}

resource "null_resource" "grant_acl" {
  for_each = local.acl_command

  triggers = {
    value        = "${each.key}-${each.value.username}-${sha256(jsonencode(each.value.accesses))}"
    data_hash    = "${each.key}-${each.value.username}-${sha256(jsonencode(each.value.accesses))}"
    command_hash = sha256(each.value.command)
  }

  provisioner "local-exec" {
    command = each.value.command
  }

  depends_on = [
    module.msk_kafka_cluster,
    aws_secretsmanager_secret_version.secret_version
  ]
}
