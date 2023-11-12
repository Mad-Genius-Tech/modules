output "cloudfront_info" {
  value = {
    for k, v in module.cloudfront : k => {
      cloudfront_distribution_id                 = v.cloudfront_distribution_id
      cloudfront_distribution_arn                = v.cloudfront_distribution_arn
      cloudfront_distribution_domain_name        = v.cloudfront_distribution_domain_name
      cloudfront_origin_access_identities        = v.cloudfront_origin_access_identities
      cloudfront_origin_access_identity_iam_arns = v.cloudfront_origin_access_identity_iam_arns
    }
  }
}