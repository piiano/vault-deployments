# Available zones in region
data "google_compute_zones" "default_zones" {
  project = var.project
  region  = var.default_region
}

data "google_compute_zones" "db_zones" {
  project = var.project
  region  = local.db_region
}

# CloudRun invoke/ingress policy
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

# Bastion image
data "google_compute_image" "cos_lts" {
  project = "cos-cloud"
  family  = "cos-113-lts"
}

data "google_secret_manager_secret" "admin_api_key" {
  count = local.pvault_admin_api_key_generate ? 0 : 1

  secret_id = var.pvault_admin_api_key.secret_id
}
