output "vault_url" {
  value = "https://${aws_alb.pvault.dns_name}"
}

output "authtoken" {
  value = "Secret Manager: ${aws_secretsmanager_secret.pvault_service_admin_api_key.name} --> retrieve value"
}
