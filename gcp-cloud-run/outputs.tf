output "vault_url" {
  description = "The URL of the Vault server"
  value       = local.vault_url
}

output "authtoken" {
  description = "Auth token"
  value       = local.pvault_admin_api_key_secret.id
}
