#############
### Proxy ###
#############
resource "google_cloud_run_v2_service" "nginx_proxy" {
  count = var.create_proxy ? 1 : 0

  name     = "${var.deployment_id}-nginx-proxy"
  location = local.client_region
  client   = "terraform"
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  annotations = {
    "piiano.io/deployment_id" = var.deployment_id
  }

  template {
    service_account = google_service_account.proxy_sa[0].email

    timeout                          = "29s"
    max_instance_request_concurrency = 300
    scaling {
      max_instance_count = 5
    }

    annotations = {
      "piiano.io/deployment_id" = var.deployment_id
    }

    containers {
      image = var.proxy_image

      env {
        name  = "TARGET_HOST"
        value = trimprefix(google_cloud_run_v2_service.pvault-server.uri, "https://")
      }

      # liveness_probe {
      #   timeout_seconds = 5
      # }
    }

    vpc_access {
      connector = google_vpc_access_connector.proxy_vault_connector[0].id
      egress    = "ALL_TRAFFIC"
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.cloud_run_secrets_access,
    google_kms_crypto_key_iam_member.crypto_key_cloud_run
  ]
}

resource "google_service_account" "proxy_sa" {
  count = var.create_proxy ? 1 : 0

  account_id   = "${var.deployment_id}-vault-proxy"
  display_name = "${var.deployment_id}-proxy service account"
}

resource "google_project_iam_member" "vault_client" {
  count = var.create_proxy ? 1 : 0

  project = var.project
  role    = "roles/run.invoker"
  member  = var.create_proxy ? google_service_account.proxy_sa[0].member : null

  condition {
    expression = "resource.name == '${google_cloud_run_v2_service.pvault-server.id}'"
    title      = "Proxy access to Vault"
  }
}

resource "google_cloud_run_v2_service_iam_policy" "proxy_noauth" {
  count = var.create_proxy ? 1 : 0

  location = google_cloud_run_v2_service.nginx_proxy[0].location
  project  = google_cloud_run_v2_service.nginx_proxy[0].project
  name     = google_cloud_run_v2_service.nginx_proxy[0].name

  policy_data = data.google_iam_policy.noauth.policy_data
}

module "proxy_internal_load_balancer" {
  count = var.create_ilb ? 1 : 0

  source                      = "./internal-load-balancer"
  prefix                      = "${var.deployment_id}-proxy"
  region                      = local.client_region
  ssl_certificate             = var.create_ilb ? file(var.ilb_ssl_certificate) : null
  ssl_certificate_private_key = var.create_ilb ? file(var.ilb_ssl_certificate_private_key) : null
  cloud_run_name              = var.create_proxy ? google_cloud_run_v2_service.nginx_proxy[0].name : google_cloud_run_v2_service.pvault-server.name
  network_id                  = local.network
  backend_ip_range            = var.ilb_backend_range
  frontend_ip_range           = var.ilb_frontend_range
  timeout                     = 30
}
