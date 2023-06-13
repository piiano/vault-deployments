resource "aws_secretsmanager_secret" "pvault_service_license" {
  count                   = var.create_secret_license ? 1 : 0
  name                    = "/${var.deployment_id}/pvault_service_license"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "pvault_service_license" {
  count         = var.create_secret_license ? 1 : 0
  secret_id     = aws_secretsmanager_secret.pvault_service_license[0].id
  secret_string = var.pvault_service_license
}

resource "random_password" "pvault_service_admin_api_key" {
  length  = 20
  special = false
}

resource "aws_secretsmanager_secret" "pvault_service_admin_api_key" {
  name                    = "/${var.deployment_id}/pvault_service_admin_api_key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "pvault_service_admin_api_key" {
  secret_id     = aws_secretsmanager_secret.pvault_service_admin_api_key.id
  secret_string = random_password.pvault_service_admin_api_key.result
}

locals {
  pvault_license_secret_arn = !var.create_secret_license && var.secret_arn_license != "" ? var.secret_arn_license : one(aws_secretsmanager_secret.pvault_service_license).arn
}
