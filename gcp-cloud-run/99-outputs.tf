
output "vault_url" {
  value = local.vault_url
}

output "authtoken" {
  value = google_secret_manager_secret.admin_api_key.id
}
