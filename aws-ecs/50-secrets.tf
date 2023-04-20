# Storing Postgres master password to secret manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "/${var.deployment_id}/db_password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = module.db.db_instance_password
}

# Storing PVAULT_SERVICE_LICENSE to secret manager
resource "aws_secretsmanager_secret" "pvault_service_license" {
  name                    = "/${var.deployment_id}/pvault_service_license"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "pvault_service_license" {
  secret_id     = aws_secretsmanager_secret.pvault_service_license.id
  secret_string = var.pvault_service_license
}

# Generating and storing PVAULT_SERVICE_ADMIN_API_KEY to secret manager
resource "random_password" "pvault_service_admin_api_key" {
  length  = 30
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
