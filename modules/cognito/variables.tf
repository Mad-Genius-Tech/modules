
variable "cognito" {
  type = map(object({
    deletion_protection = optional(string)
    alias_attributes    = optional(list(string))
    username_configuration = optional(object({
      case_sensitive = optional(bool)
    }))
    auto_verified_attributes                      = optional(list(string))
    attributes_require_verification_before_update = optional(list(string))
    verification_message_template = optional(list(object({
      sms_message           = optional(string)
      email_message         = optional(string)
      email_subject         = optional(string)
      email_message_by_link = optional(string)
      email_subject_by_link = optional(string)
      default_email_option  = optional(string)
    })))
    recovery_mechanisms = optional(list(object({
      name     = optional(string)
      priority = optional(number)
    })))
    string_schemas = optional(list(object({
      attribute_data_type      = optional(string)
      developer_only_attribute = optional(bool)
      mutable                  = optional(bool)
      name                     = optional(string)
      required                 = optional(bool)
      string_attribute_constraints = optional(object({
        min_length = optional(number)
        max_length = optional(number)
      }))
    })))
    email_configuration = optional(list(object({
      from_email_address    = optional(string)
      source_arn            = optional(string)
      email_sending_account = optional(string)
    })))
    explicit_auth_flows                  = optional(list(string))
    prevent_user_existence_errors        = optional(string)
    enable_token_revocation              = optional(bool)
    access_token_validity                = optional(number)
    id_token_validity                    = optional(number)
    callback_urls                        = optional(list(string))
    supported_identity_providers         = optional(list(string))
    allowed_oauth_flows_user_pool_client = optional(bool)
    allowed_oauth_flows                  = optional(list(string))
    allowed_oauth_scopes                 = optional(list(string))
    read_attributes                      = optional(list(string))
    write_attributes                     = optional(list(string))
    token_validity_units = optional(list(object({
      access_token  = optional(string)
      id_token      = optional(string)
      refresh_token = optional(string)
    })))
  }))
}
