output "pvault_url" {
  value = {
    type  = "ENV"
    name  = "PVAULT_URL"
    value = "https://${aws_apprunner_vpc_ingress_connection.pvault.domain_name}"
  }
}

output "pvault_api_key" {
  value = {
    type  = "SECRET"
    name  = "PVAULT_API_KEY"
    value = aws_secretsmanager_secret.pvault_service_admin_api_key.arn
  }
}
