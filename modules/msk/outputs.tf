output "grant_acls" {
  value = { for k, v in local.acl_command : k => v.command }
}

output "name" {
  description = "Name of the MSK cluster"
  value = {
    for k, v in module.msk_kafka_cluster : k => v.cluster_name
  }
}

output "arn" {
  description = "Amazon Resource Name (ARN) of the MSK cluster"
  value = {
    for k, v in module.msk_kafka_cluster : k => v.arn
  }
}

output "cmd_load_env" {
  value = {
    for k, v in module.msk_kafka_cluster : k => "source ./utils/commands/load-env.sh ${var.aws_profile} ${v.bootstrap_brokers_sasl_iam}"
  }
}

output "list_acls" {
  value = {
    for k, v in module.msk_kafka_cluster : k => "kafka-acls.sh --bootstrap-server ${v.bootstrap_brokers_sasl_iam} --command-config ./utils/client-configs/iam.properties --list --principal User:admin"
  }
}

output "bootstrap_brokers_sasl_iam" {
  description = "One or more DNS names (or IP addresses) and SASL IAM port pairs. This attribute will have a value if `encryption_in_transit_client_broker` is set to `TLS_PLAINTEXT` or `TLS` and `client_authentication_sasl_iam` is set to `true`"
  value = {
    for k, v in module.msk_kafka_cluster : k => v.bootstrap_brokers_sasl_iam
  }
}

output "bootstrap_brokers_sasl_scram" {
  description = "One or more DNS names (or IP addresses) and SASL SCRAM port pairs. This attribute will have a value if `encryption_in_transit_client_broker` is set to `TLS_PLAINTEXT` or `TLS` and `client_authentication_sasl_scram` is set to `true`"
  value = {
    for k, v in module.msk_kafka_cluster : k => v.bootstrap_brokers_sasl_scram
  }
}