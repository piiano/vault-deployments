
######################
### Secret Manager ###
######################
resource "google_secret_manager_secret" "db_password_secret" {
  secret_id = "${var.deployment_id}-vault-db-password"

  replication {
    user_managed {
      replicas {
        location = local.vault_region
      }
    }
  }
  depends_on = [google_project_service.apis["secretmanager.googleapis.com"]]
}

resource "google_secret_manager_secret_version" "db_password_secret_version" {
  secret      = google_secret_manager_secret.db_password_secret.id
  secret_data = module.postgresql-db.generated_user_password
}

resource "google_secret_manager_secret_iam_member" "cloud_run_secrets_access" {
  secret_id = google_secret_manager_secret.db_password_secret.secret_id
  member    = "serviceAccount:${google_service_account.pvault-server-sa.email}"
  role      = "roles/secretmanager.secretAccessor"
}


resource "google_secret_manager_secret" "admin_api_key" {
  secret_id = "${var.deployment_id}-admin-api-key"

  replication {
    user_managed {
      replicas {
        location = local.vault_region
      }
    }
  }
  depends_on = [google_project_service.apis["secretmanager.googleapis.com"]]
}

resource "random_password" "admin_api_key" {
  length           = 32
  special          = true
  override_special = "@#%&*-_=+[]<>:?"
  keepers = {
    change = false
  }
}

resource "google_secret_manager_secret_version" "admin_api_key_version" {
  secret      = google_secret_manager_secret.admin_api_key.id
  secret_data = random_password.admin_api_key.result
}

resource "google_secret_manager_secret_iam_member" "cloud_run_admin_api_key_secret_access" {
  secret_id = google_secret_manager_secret.admin_api_key.secret_id
  member    = "serviceAccount:${google_service_account.pvault-server-sa.email}"
  role      = "roles/secretmanager.secretAccessor"
}

resource "google_secret_manager_secret_iam_member" "cli_vm_admin_api_key_secret_access" {
  secret_id = google_secret_manager_secret.admin_api_key.secret_id
  member    = "serviceAccount:${google_service_account.pvault-cli-sa.email}"
  role      = "roles/secretmanager.secretAccessor"
}
