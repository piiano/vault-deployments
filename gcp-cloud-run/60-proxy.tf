
locals {
  client_region = coalesce(
    var.client_region,
    var.vault_region,
    var.default_region
  )
}

resource "google_cloud_run_service" "nginx_proxy" {
  name     = "${var.deployment_id}-nginx-proxy"
  location = local.client_region
  provider = google-beta

  metadata {
    annotations = {
      "run.googleapis.com/client-name" = "terraform"
      "run.googleapis.com/ingress"     = "internal-and-cloud-load-balancing"
    }
  }

  template {
    spec {
      timeout_seconds       = 29
      container_concurrency = 300
      containers {
        image = var.proxy_image
        env {
          name  = "TARGET_HOST"
          value = trimprefix(google_cloud_run_service.pvault-server.status[0].url, "https://")
        }
      }
      service_account_name = google_service_account.proxy_sa.email
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = "5"
        "run.googleapis.com/client-name"          = "terraform"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.proxy_vault_connector.name
        "run.googleapis.com/vpc-access-egress"    = "all-traffic"
      }
    }
  }
  autogenerate_revision_name = true
}


resource "google_service_account" "proxy_sa" {
  account_id   = "${var.deployment_id}-vault-proxy"
  display_name = "${var.deployment_id}-proxy service account"
}

resource "google_project_iam_member" "vault_client" {
  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.proxy_sa.email}"

  condition {
    expression = "resource.name == '${google_cloud_run_service.pvault-server.id}'"
    title      = "Proxy access to Vault"
  }
}

resource "google_cloud_run_service_iam_policy" "proxy_noauth" {
  location = google_cloud_run_service.nginx_proxy.location
  project  = google_cloud_run_service.nginx_proxy.project
  service  = google_cloud_run_service.nginx_proxy.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

module "proxy_internal_load_balancer" {
  source            = "./internal-load-balancer"
  prefix            = "${var.deployment_id}-proxy"
  region            = local.client_region
  cloud_run_name    = google_cloud_run_service.nginx_proxy.name
  network_id        = module.vpc.network_id
  backend_ip_range  = var.ilb_backend_range
  frontend_ip_range = var.ilb_frontend_range
  timeout           = 30
}
