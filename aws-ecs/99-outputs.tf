output "vault_url" {
  value = "http://${aws_alb.pvault.dns_name}"
}

output "authtoken" {
  value = "Secret Manager: ${aws_secretsmanager_secret.pvault_service_admin_api_key.name} --> retrieve value"
}

output "bastion_instance_id" {
  value = var.create_bastion  ? aws_instance.bastion[0].id : null
}
