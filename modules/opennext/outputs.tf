output "cloudfront_log_bucket" {
  value = module.cloudfront_logs.s3_bucket_id
}