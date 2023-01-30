output "vault_url" {
  value = "https://${aws_apprunner_vpc_ingress_connection.pvault.domain_name}"
}

output "authtoken" {
  value = "Secret Manager: ${aws_secretsmanager_secret.pvault_service_admin_api_key.name} --> retrieve value"
}
