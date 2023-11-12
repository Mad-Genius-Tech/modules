output "key_info" {
  value = {
    for k, v in module.kms : k => {
      key_id             = v.key_id
      key_arn            = v.key_arn
      aliases            = v.aliases
      external_key_state = v.external_key_state
    }
  }
}

output "sops_arn" {
  value = try(coalesce(lookup(module.kms["sops"], "key_arn", null), ""), "")
}
