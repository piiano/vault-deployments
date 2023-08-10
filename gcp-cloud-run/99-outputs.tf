
output "vault_url" {
  description = "The URL of the Vault server"
  value = local.vault_url
}

output "authtoken" {
  description = "Auth token"
  value = google_secret_manager_secret.admin_api_key.id
}
