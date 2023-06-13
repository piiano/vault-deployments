output "pvault_url" {
  value = {
    type  = "ENV"
    name  = "PVAULT_URL"
    value = var.is_publically_accessible ? aws_apprunner_service.pvault.service_url : "https://${aws_apprunner_vpc_ingress_connection.pvault[0].domain_name}"
  }
}

output "pvault_api_key" {
  value = {
    type  = "SECRET"
    name  = "PVAULT_API_KEY"
    value = aws_secretsmanager_secret.pvault_service_admin_api_key.arn
  }
}

output "apprunner_service_arn" {
  value = aws_apprunner_service.pvault.arn
}
