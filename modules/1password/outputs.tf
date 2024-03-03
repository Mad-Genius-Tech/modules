output "secrets" {
  value     = local.all_passwords
  sensitive = true
}