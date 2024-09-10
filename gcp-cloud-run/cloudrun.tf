################################
### Cloud Run (Vault Server) ###
################################
resource "google_cloud_run_v2_service" "pvault-server" {
  name     = "${var.deployment_id}-pvault-server"
  location = local.pvault_region
  client   = "terraform"
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  annotations = {
    "piiano.io/deployment_id" = var.deployment_id
  }

  template {
    service_account = google_service_account.pvault-server-sa.email

    execution_environment            = "EXECUTION_ENVIRONMENT_GEN2"
    timeout                          = "28s"
    max_instance_request_concurrency = var.cloud_run_scaling.max_instance_request_concurrency
    scaling {
      min_instance_count = var.cloud_run_scaling.min_instance_count
      max_instance_count = var.cloud_run_scaling.max_instance_count
    }

    annotations = {
      "piiano.io/deployment_id" = var.deployment_id
    }

    containers {
      image = "${var.pvault_repository}:${var.pvault_tag}"

      resources {
        limits = var.cloud_run_resources.limits
      }

      dynamic "env" {
        for_each = local.pvault_env
        content {
          name  = env.key
          value = env.value
        }
      }
      env {
        name = "PVAULT_DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password_secret.secret_id
            version = "latest"
          }
        }
      }
      env {
        name = "PVAULT_SERVICE_ADMIN_API_KEY"
        value_source {
          secret_key_ref {
            secret  = local.pvault_admin_api_key_secret.secret_id
            version = "latest"
          }
        }
      }

      ports {
        container_port = 8123
      }

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 1
        period_seconds        = 1
        failure_threshold     = 60
        http_get {
          path = "/api/pvlt/1.0/data/info/health"
        }
      }
      liveness_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3
        http_get {
          path = "/api/pvlt/1.0/data/info/health"
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = local.pvault_db_socket_folder
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [module.postgresql-db.instance_connection_name]
      }
    }

    vpc_access {
      connector = google_vpc_access_connector.connector_vault_cloud_run.id
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }

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
  member  = google_service_account.pvault-server-sa.member

  condition {
    expression  = "resource.name == 'projects/${var.project}/instances/${module.postgresql-db.instance_name}' && resource.type == 'sqladmin.googleapis.com/Instance' && resource.service == 'sqladmin.googleapis.com'"
    title       = "Cloud SQL access to DB ${module.postgresql-db.instance_name}"
    description = "Cloud SQL access to DB ${module.postgresql-db.instance_name}"
  }
}

resource "google_cloud_run_v2_service_iam_policy" "noauth" {
  location = google_cloud_run_v2_service.pvault-server.location
  project  = google_cloud_run_v2_service.pvault-server.project
  name     = google_cloud_run_v2_service.pvault-server.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
