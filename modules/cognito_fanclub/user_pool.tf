
locals {
  default_settings = {
    deletion_protection = "INACTIVE"
    mfa_configuration   = "OFF"
    # Cognito user pool sign-in options
    alias_attributes = [
      "email",
      "preferred_username",
      # "phone_number",
    ]
    username_configuration = {
      case_sensitive = false
    }
    auto_verified_attributes = [
      "email",
    ]
    attributes_require_verification_before_update = [
      "email"
    ]
    verification_message_template = [{
      sms_message           = "Your verification code is {####}."
      email_message         = "To verify your email <a href=\"https://dev.fanclub.co/auth/emailverified?code={####}\">click here</a>"
      email_subject         = "Your verification link"
      email_message_by_link = "Please click the link below to verify your email address. {##Verify Email##}"
      email_subject_by_link = "Your verification link"
      default_email_option  = "CONFIRM_WITH_CODE"
    }]
    recovery_mechanisms = [{
      name     = "verified_email"
      priority = 1
    }]
    secret_vars         = {}
    email_configuration = [{}]
    lambda_config       = [{}]
    domain_name         = "${var.org_name}-${var.stage_name}-cognito"
    wildcard_domain     = true
    string_schemas = [{
      attribute_data_type      = "String"
      mutable                  = true
      name                     = "email"
      required                 = true
      developer_only_attribute = false
      string_attribute_constraints = {
        min_length = 0
        max_length = 2048
      }
    }]
    explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
    prevent_user_existence_errors        = "ENABLED"
    enable_token_revocation              = true
    access_token_validity                = 60 # minutes
    id_token_validity                    = 60 # minutes
    callback_urls                        = ["https://jwt.io"]
    logout_urls                          = []
    supported_identity_providers         = ["COGNITO"]
    google_client_id                     = ""
    google_client_secret                 = ""
    allowed_oauth_flows_user_pool_client = true
    allowed_oauth_flows                  = ["implicit"]
    allowed_oauth_scopes                 = ["email", "openid", "phone"]
    read_attributes = [
      "address",
      "birthdate",
      "email",
      "email_verified",
      "family_name",
      "gender",
      "given_name",
      "locale",
      "middle_name",
      "name",
      "nickname",
      "phone_number",
      "phone_number_verified",
      "picture",
      "preferred_username",
      "profile",
      "updated_at",
      "website",
      "zoneinfo",
      "custom:google_name",
    ]
    write_attributes = [
      "address",
      "birthdate",
      "email",
      "family_name",
      "gender",
      "given_name",
      "locale",
      "middle_name",
      "name",
      "nickname",
      "phone_number",
      "picture",
      "preferred_username",
      "profile",
      "updated_at",
      "website",
      "zoneinfo",
      "custom:google_name",
    ]
    token_validity_units = [{
      access_token  = "minutes"
      id_token      = "minutes"
      refresh_token = "days"
    }]

    create_identity_pool             = true
    allow_unauthenticated_identities = true
    allow_classic_flow               = false

  }

  env_default_settings = {
    prod = merge(local.default_settings,
      {
        deletion_protection = "ACTIVE"
      }
    )
  }

  merged_default_settings = can(local.env_default_settings[var.stage_name]) ? lookup(local.env_default_settings, var.stage_name, local.default_settings) : local.default_settings

  cognito_map = {
    for k, v in var.cognito : k => {
      "identifier"                                    = "${module.context.id}-${k}"
      "deletion_protection"                           = try(coalesce(lookup(v, "deletion_protection", null), local.merged_default_settings.deletion_protection), local.merged_default_settings.deletion_protection)
      "mfa_configuration"                             = try(coalesce(lookup(v, "mfa_configuration", null), local.merged_default_settings.mfa_configuration), local.merged_default_settings.mfa_configuration)
      "domain_name"                                   = try(coalesce(lookup(v, "domain_name", null), local.merged_default_settings.domain_name), local.merged_default_settings.domain_name)
      "wildcard_domain"                               = try(coalesce(lookup(v, "wildcard_domain", null), local.merged_default_settings.wildcard_domain), local.merged_default_settings.wildcard_domain)
      "alias_attributes"                              = try(coalesce(lookup(v, "alias_attributes", null), local.merged_default_settings.alias_attributes), local.merged_default_settings.alias_attributes)
      "username_configuration"                        = try(coalesce(lookup(v, "username_configuration", null), local.merged_default_settings.username_configuration), local.merged_default_settings.username_configuration)
      "auto_verified_attributes"                      = try(coalesce(lookup(v, "auto_verified_attributes", null), local.merged_default_settings.auto_verified_attributes), local.merged_default_settings.auto_verified_attributes)
      "attributes_require_verification_before_update" = try(coalesce(lookup(v, "attributes_require_verification_before_update", null), local.merged_default_settings.attributes_require_verification_before_update), local.merged_default_settings.attributes_require_verification_before_update)
      "verification_message_template"                 = try(coalesce(lookup(v, "verification_message_template", null), local.merged_default_settings.verification_message_template), local.merged_default_settings.verification_message_template)
      "recovery_mechanisms"                           = try(coalesce(lookup(v, "recovery_mechanisms", null), local.merged_default_settings.recovery_mechanisms), local.merged_default_settings.recovery_mechanisms)
      "string_schemas"                                = try(coalesce(lookup(v, "string_schemas", null), local.merged_default_settings.string_schemas), local.merged_default_settings.string_schemas)
      "email_configuration"                           = try(coalesce(lookup(v, "email_configuration", null), local.merged_default_settings.email_configuration), local.merged_default_settings.email_configuration)
      "lambda_config"                                 = try(coalesce(lookup(v, "lambda_config", null), local.merged_default_settings.lambda_config), local.merged_default_settings.lambda_config)
      "explicit_auth_flows"                           = try(coalesce(lookup(v, "explicit_auth_flows", null), local.merged_default_settings.explicit_auth_flows), local.merged_default_settings.explicit_auth_flows)
      "prevent_user_existence_errors"                 = try(coalesce(lookup(v, "prevent_user_existence_errors", null), local.merged_default_settings.prevent_user_existence_errors), local.merged_default_settings.prevent_user_existence_errors)
      "enable_token_revocation"                       = try(coalesce(lookup(v, "enable_token_revocation", null), local.merged_default_settings.enable_token_revocation), local.merged_default_settings.enable_token_revocation)
      "access_token_validity"                         = try(coalesce(lookup(v, "access_token_validity", null), local.merged_default_settings.access_token_validity), local.merged_default_settings.access_token_validity)
      "id_token_validity"                             = try(coalesce(lookup(v, "id_token_validity", null), local.merged_default_settings.id_token_validity), local.merged_default_settings.id_token_validity)
      "callback_urls"                                 = try(coalesce(lookup(v, "callback_urls", null), local.merged_default_settings.callback_urls), local.merged_default_settings.callback_urls)
      "logout_urls"                                   = try(coalesce(lookup(v, "logout_urls", null), local.merged_default_settings.logout_urls), local.merged_default_settings.logout_urls)
      "supported_identity_providers"                  = try(coalesce(lookup(v, "supported_identity_providers", null), local.merged_default_settings.supported_identity_providers), local.merged_default_settings.supported_identity_providers)
      "allowed_oauth_flows_user_pool_client"          = try(coalesce(lookup(v, "allowed_oauth_flows_user_pool_client", null), local.merged_default_settings.allowed_oauth_flows_user_pool_client), local.merged_default_settings.allowed_oauth_flows_user_pool_client)
      "allowed_oauth_flows"                           = try(coalesce(lookup(v, "allowed_oauth_flows", null), local.merged_default_settings.allowed_oauth_flows), local.merged_default_settings.allowed_oauth_flows)
      "allowed_oauth_scopes"                          = try(coalesce(lookup(v, "allowed_oauth_scopes", null), local.merged_default_settings.allowed_oauth_scopes), local.merged_default_settings.allowed_oauth_scopes)
      "read_attributes"                               = distinct(concat(try(coalesce(lookup(v, "read_attributes", null), local.merged_default_settings.read_attributes), local.merged_default_settings.read_attributes), local.merged_default_settings.read_attributes))
      "write_attributes"                              = distinct(concat(try(coalesce(lookup(v, "write_attributes", null), local.merged_default_settings.write_attributes), local.merged_default_settings.write_attributes), local.merged_default_settings.write_attributes))
      "token_validity_units"                          = try(coalesce(lookup(v, "token_validity_units", null), local.merged_default_settings.token_validity_units), local.merged_default_settings.token_validity_units)
      "allow_unauthenticated_identities"              = try(coalesce(lookup(v, "allow_unauthenticated_identities", null), local.merged_default_settings.allow_unauthenticated_identities), local.merged_default_settings.allow_unauthenticated_identities)
      create_identity_pool                            = try(coalesce(lookup(v, "create_identity_pool", null), local.merged_default_settings.create_identity_pool), local.merged_default_settings.create_identity_pool)
      "allow_classic_flow"                            = try(coalesce(lookup(v, "allow_classic_flow", null), local.merged_default_settings.allow_classic_flow), local.merged_default_settings.allow_classic_flow)
      google_client_id                                = try(coalesce(lookup(v, "google_client_id", null), local.merged_default_settings.google_client_id), local.merged_default_settings.google_client_id)
      google_client_secret                            = try(coalesce(lookup(v, "google_client_secret", null), local.merged_default_settings.google_client_secret), local.merged_default_settings.google_client_secret)
      secret_vars                                     = try(coalesce(lookup(v, "secret_vars", null), local.merged_default_settings.secret_vars), local.merged_default_settings.secret_vars)
    } if coalesce(lookup(v, "create", true), true)
  }
}

resource "aws_cognito_user_pool" "user_pool" {
  for_each                 = local.cognito_map
  name                     = each.value.identifier
  mfa_configuration        = each.value.mfa_configuration
  deletion_protection      = each.value.deletion_protection
  alias_attributes         = each.value.alias_attributes
  auto_verified_attributes = each.value.auto_verified_attributes

  dynamic "username_configuration" {
    for_each = length(each.value.username_configuration) == 0 ? [] : [each.value.username_configuration]
    content {
      case_sensitive = lookup(username_configuration.value, "case_sensitive")
    }
  }

  dynamic "user_attribute_update_settings" {
    for_each = length(each.value.attributes_require_verification_before_update) == 0 ? [] : [each.value.attributes_require_verification_before_update]
    content {
      attributes_require_verification_before_update = each.value.attributes_require_verification_before_update
    }
  }

  dynamic "schema" {
    for_each = each.value.string_schemas == null ? [] : each.value.string_schemas
    content {
      attribute_data_type      = lookup(schema.value, "attribute_data_type")
      developer_only_attribute = lookup(schema.value, "developer_only_attribute")
      mutable                  = lookup(schema.value, "mutable")
      name                     = lookup(schema.value, "name")
      required                 = lookup(schema.value, "required")

      # string_attribute_constraints
      dynamic "string_attribute_constraints" {
        for_each = length(keys(lookup(schema.value, "string_attribute_constraints", {}))) == 0 ? [{}] : [lookup(schema.value, "string_attribute_constraints", {})]
        content {
          min_length = lookup(string_attribute_constraints.value, "min_length", null)
          max_length = lookup(string_attribute_constraints.value, "max_length", null)
        }
      }
    }
  }

  dynamic "verification_message_template" {
    for_each = each.value.verification_message_template
    content {
      sms_message           = lookup(verification_message_template.value, "sms_message")
      email_message         = lookup(verification_message_template.value, "email_message")
      email_subject         = lookup(verification_message_template.value, "email_subject")
      email_message_by_link = lookup(verification_message_template.value, "email_message_by_link")
      email_subject_by_link = lookup(verification_message_template.value, "email_subject_by_link")
      default_email_option  = lookup(verification_message_template.value, "default_email_option")
    }
  }

  dynamic "email_configuration" {
    for_each = each.value.email_configuration
    content {
      from_email_address    = lookup(email_configuration.value, "from_email_address", null)
      source_arn            = lookup(email_configuration.value, "source_arn", null)
      email_sending_account = lookup(email_configuration.value, "email_sending_account", null)
    }
  }

  dynamic "lambda_config" {
    for_each = each.value.lambda_config
    content {
      custom_message      = lookup(lambda_config.value, "custom_message", null)
      post_confirmation   = lookup(lambda_config.value, "post_confirmation", null)
      post_authentication = lookup(lambda_config.value, "post_authentication", null)
      pre_sign_up         = lookup(lambda_config.value, "pre_sign_up", null)
    }
  }

  dynamic "account_recovery_setting" {
    for_each = length(each.value.recovery_mechanisms) == 0 ? [] : [1]
    content {
      dynamic "recovery_mechanism" {
        for_each = each.value.recovery_mechanisms
        content {
          name     = lookup(recovery_mechanism.value, "name")
          priority = lookup(recovery_mechanism.value, "priority")
        }
      }
    }
  }

  dynamic "software_token_mfa_configuration" {
    for_each = each.value.mfa_configuration != "OFF" ? [1] : []
    content {
      enabled = each.value.mfa_configuration != "OFF"
    }
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [
      #lambda_config
      password_policy,
      schema
    ]
  }
}

resource "aws_cognito_user_pool_client" "client" {
  for_each                             = local.cognito_map
  name                                 = "${each.value.identifier}-client"
  user_pool_id                         = aws_cognito_user_pool.user_pool[each.key].id
  explicit_auth_flows                  = each.value.explicit_auth_flows
  prevent_user_existence_errors        = each.value.prevent_user_existence_errors
  callback_urls                        = each.value.callback_urls
  logout_urls                          = each.value.logout_urls
  supported_identity_providers         = each.value.supported_identity_providers
  allowed_oauth_flows_user_pool_client = each.value.allowed_oauth_flows_user_pool_client
  allowed_oauth_flows                  = each.value.allowed_oauth_flows
  allowed_oauth_scopes                 = each.value.allowed_oauth_scopes
  read_attributes                      = each.value.read_attributes
  write_attributes                     = each.value.write_attributes
  # write_attributes                    = ["custom:chime_user_id", "custom:cognito_identity_id", "custom:google_id", "custom:google_name"]
  enable_token_revocation = each.value.enable_token_revocation
  access_token_validity   = each.value.access_token_validity
  id_token_validity       = each.value.id_token_validity
  # token_validity_units
  dynamic "token_validity_units" {
    for_each = each.value.token_validity_units
    content {
      access_token  = lookup(token_validity_units.value, "access_token", null)
      id_token      = lookup(token_validity_units.value, "id_token", null)
      refresh_token = lookup(token_validity_units.value, "refresh_token", null)
    }
  }
  depends_on = [aws_cognito_identity_provider.google]
}

resource "aws_cognito_identity_provider" "google" {
  for_each      = { for k, v in local.cognito_map : k => v if contains(v.supported_identity_providers, "Google") }
  user_pool_id  = aws_cognito_user_pool.user_pool[each.key].id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes              = "email profile"
    client_id                     = jsondecode(data.aws_secretsmanager_secret_version.secret["${each.key}|google_client_id"].secret_string)["COGNITO_GOOGLE_CLIENT_ID"]
    client_secret                 = jsondecode(data.aws_secretsmanager_secret_version.secret["${each.key}|google_client_secret"].secret_string)["COGNITO_GOOGLE_CLIENT_SECRET"]
    attributes_url                = "https://people.googleapis.com/v1/people/me?personFields="
    attributes_url_add_attributes = "true"
    authorize_url                 = "https://accounts.google.com/o/oauth2/v2/auth"
    oidc_issuer                   = "https://accounts.google.com"
    token_request_method          = "POST"
    token_url                     = "https://www.googleapis.com/oauth2/v4/token"
  }

  attribute_mapping = {
    "name"               = "name"
    "email"              = "email"
    "username"           = "sub"
    "custom:google_name" = "name"
  }
}

resource "aws_cognito_user_pool_domain" "domain" {
  for_each        = local.cognito_map
  domain          = each.value.domain_name
  user_pool_id    = aws_cognito_user_pool.user_pool[each.key].id
  certificate_arn = !strcontains(each.value.domain_name, ".") ? null : (each.value.wildcard_domain ? data.aws_acm_certificate.wildcard[each.key].arn : data.aws_acm_certificate.non_wildcard[each.key].arn)
}


provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

data "aws_acm_certificate" "wildcard" {
  for_each = { for k, v in local.cognito_map : k => v if v.wildcard_domain && strcontains(v.domain_name, ".") }
  domain   = join(".", slice(split(".", each.value.domain_name), 1, length(split(".", each.value.domain_name))))
  statuses = ["ISSUED"]
  provider = aws.us-east-1
}

data "aws_acm_certificate" "non_wildcard" {
  for_each = { for k, v in local.cognito_map : k => v if !v.wildcard_domain && strcontains(v.domain_name, ".") }
  domain   = each.value.domain_name
  statuses = ["ISSUED"]
  provider = aws.us-east-1
}

locals {
  secret_vars_map = merge([
    for k, v in local.cognito_map : {
      for var in keys(v.secret_vars) : "${k}|${var}" => v.secret_vars[var]
    } if length(v.secret_vars) > 0
  ]...)
}

data "aws_secretsmanager_secret" "secret" {
  for_each = local.secret_vars_map
  name     = each.value.secret_path
}

data "aws_secretsmanager_secret_version" "secret" {
  for_each  = local.secret_vars_map
  secret_id = data.aws_secretsmanager_secret.secret[each.key].id
}
