
locals {
  default_subscription_status = "OPT_IN"
}

resource "aws_ses_domain_identity" "ses_domain_identity" {
  count  = var.ses_domain_name != "" ? 1 : 0
  domain = var.ses_domain_name
}

resource "aws_ses_domain_dkim" "this" {
  count  = var.ses_domain_name != "" ? 1 : 0
  domain = aws_ses_domain_identity.ses_domain_identity[0].domain
}

# resource "aws_ses_domain_mail_from" "this" {
#   count  = var.ses_domain_name != "" ? 1 : 0
#   domain           = aws_ses_domain_identity.ses_domain_identity[0].domain
#   mail_from_domain = "bounce.${ aws_ses_domain_identity.ses_domain_identity[0].domain}"
# }

resource "aws_sesv2_email_identity" "email_identity" {
  for_each       = length(var.ses_emails) > 0 ? toset(var.ses_emails) : []
  email_identity = each.value
}

resource "aws_sesv2_contact_list" "contact_list" {
  count             = var.contact_list_name != "" ? 1 : 0
  contact_list_name = var.contact_list_name
  description       = var.contact_list_description

  dynamic "topic" {
    for_each = var.topic_name != "" ? [1] : []
    content {
      default_subscription_status = local.default_subscription_status
      description                 = var.topic_description
      display_name                = var.topic_display_name
      topic_name                  = var.topic_name
    }
  }
  tags = local.tags
}