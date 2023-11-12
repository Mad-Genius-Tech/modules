output "s3_info" {
  value = {
    for k, v in module.s3_bucket : k => {
      s3_bucket_id                          = v.s3_bucket_id
      s3_bucket_arn                         = v.s3_bucket_arn
      s3_bucket_bucket_domain_name          = v.s3_bucket_bucket_domain_name
      s3_bucket_bucket_regional_domain_name = v.s3_bucket_bucket_regional_domain_name
      s3_bucket_website_endpoint            = v.s3_bucket_website_endpoint
      s3_bucket_website_domain              = v.s3_bucket_website_domain
    }
  }
}