
module "config_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"
  bucket  = "${module.context.id}-config"
  versioning = {
    enabled = true
  }
}

module "wordpress_bucket" {
  source                  = "terraform-aws-modules/s3-bucket/aws"
  version                 = "4.1.0"
  bucket                  = "${module.context.id}-images"
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
  object_ownership        = "BucketOwnerPreferred"
  tags                    = local.tags
}

locals {
  tpl_files = fileset("${path.module}/templates", "*.tpl")
  cfg_files = fileset("${path.module}/configs", "*.*")
}

resource "local_file" "template_files" {
  for_each = { for file in local.tpl_files : file => replace(file, "/\\.tpl$/", "") }
  filename = "${path.module}/templates/${each.value}"
  content = templatefile("${path.module}/templates/${each.key}", {
    domain_name = var.domain_name
  })
}

resource "aws_s3_bucket_object" "config" {
  for_each = { for k in local.cfg_files : k => k }
  bucket   = module.config_bucket.s3_bucket_id
  key      = "config/${each.value}"
  source   = "${path.module}/configs/${each.value}"
  etag     = filemd5("${path.module}/configs/${each.value}")
  tags     = local.tags
}

resource "aws_s3_bucket_object" "template" {
  for_each = { for file in local.tpl_files : file => {
    file_name   = replace(file, "/\\.tpl$/", "")
    content_md5 = local_file.template_files[file].content_md5
    }
  }
  bucket = module.config_bucket.s3_bucket_id
  key    = "config/${each.value.file_name}"
  source = "${path.module}/templates/${each.value.file_name}"
  tags   = local.tags
  depends_on = [
    local_file.template_files
  ]
}
