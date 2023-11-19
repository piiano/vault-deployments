
################################
### Cloud Run (Vault Server) ###
################################

locals {
  pvault_region = coalesce(var.pvault_region, var.default_region)

  env_keys = tolist(keys(var.pvault_env_vars))
}

resource "google_cloud_run_service" "pvault-server" {
  name     = "${var.deployment_id}-pvault-server"
  location = local.pvault_region
  provider = google-beta

  metadata {
    annotations = {
      "run.googleapis.com/client-name" = "terraform"
      "run.googleapis.com/ingress"     = "internal"
    }
  }

  template {
    spec {
      timeout_seconds       = 28
      container_concurrency = 100
      containers {
        image = "${var.pvault_repository}:${var.pvault_tag}"
        dynamic "env" {
          for_each = local.env_keys
          content {
            name  = local.env_keys[env.key]
            value = var.pvault_env_vars[local.env_keys[env.key]]
          }
        }
        env {
          name  = "PVAULT_LOG_CUSTOMER_IDENTIFIER"
          value = var.pvault_log_customer_identifier
        }
        env {
          name  = "PVAULT_LOG_CUSTOMER_ENV"
          value = var.pvault_log_customer_env
        }
        env {
          name  = "PVAULT_TLS_ENABLE"
          value = "false"
        }
        env {
          name  = "PVAULT_DB_REQUIRE_TLS"
          value = "false"
        }
        env {
          name  = "PVAULT_DB_HOSTNAME"
          value = module.postgresql-db.private_ip_address
        }
        env {
          name  = "PVAULT_DB_NAME"
          value = var.cloudsql_name
        }
        env {
          name  = "PVAULT_DB_USER"
          value = var.cloudsql_username
        }
        env {
          name  = "PVAULT_SERVICE_LICENSE"
          value = var.pvault_service_license
        }
        env {
          name  = "PVAULT_SERVICE_TIMEOUT_SECONDS"
          value = "27"
        }
        env {
          name  = "PVAULT_KMS_URI"
          value = "gcp-kms://${google_kms_crypto_key.vault-encryption-key.key_ring}/cryptoKeys/${google_kms_crypto_key.vault-encryption-key.name}"
        }
        env {
          name  = "PVAULT_DEVMODE"
          value = var.pvault_devmode ? "1" : "0"
        }
        env {
          name = "PVAULT_DB_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.db_password_secret.secret_id
              key  = "latest"
            }
          }
        }
        env {
          name = "PVAULT_SERVICE_ADMIN_API_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.admin_api_key.secret_id
              key  = "latest"
            }
          }
        }
        ports {
          container_port = 8123
        }
      }
      service_account_name = google_service_account.pvault-server-sa.email
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = "5"
        "run.googleapis.com/cloudsql-instances"   = module.postgresql-db.instance_connection_name
        "run.googleapis.com/client-name"          = "terraform"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector_vault_cloud_run.id
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
  }
  autogenerate_revision_name = true
  depends_on = [
    google_secret_manager_secret_iam_member.cloud_run_secrets_access,
    google_kms_crypto_key_iam_member.crypto_key_cloud_run
  ]
}

resource "google_service_account" "pvault-server-sa" {
  account_id   = "${var.deployment_id}-pvault-server"
  display_name = "${var.deployment_id}-pvault-server service account"
}

resource "google_project_iam_member" "pvault_sql_client" {
  project = var.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.pvault-server-sa.email}"

  condition {
    expression  = "resource.name == 'projects/${var.project}/instances/${module.postgresql-db.instance_name}' && resource.type == 'sqladmin.googleapis.com/Instance' && resource.service == 'sqladmin.googleapis.com'"
    title       = "Cloud SQL access to DB ${module.postgresql-db.instance_name}"
    description = "Cloud SQL access to DB ${module.postgresql-db.instance_name}"
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.pvault-server.location
  project  = google_cloud_run_service.pvault-server.project
  service  = google_cloud_run_service.pvault-server.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
