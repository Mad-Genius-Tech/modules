output "ecr_repository" {
  value = {
    for k, v in module.ecr_repository : k => {
      repository_url = v.repository_url
    }
  }
}