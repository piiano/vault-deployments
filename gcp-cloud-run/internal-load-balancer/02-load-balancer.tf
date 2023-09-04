
resource "google_compute_subnetwork" "vault_ilb_backend_subnet" {
  provider                 = google-beta
  name                     = "${var.prefix}-ilb-backend-subnet"
  region                   = var.region
  ip_cidr_range            = var.backend_ip_range
  purpose                  = "PRIVATE"
  role                     = "ACTIVE"
  network                  = var.network_id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "vault_ilb_frontend_subnet" {
  provider      = google-beta
  region        = var.region
  name          = "${var.prefix}-ilb-frontend-subnet"
  ip_cidr_range = var.frontend_ip_range
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"
  network       = var.network_id
}

resource "google_compute_region_network_endpoint_group" "serverless_backend_neg" {
  provider              = google-beta
  region                = var.region
  name                  = "${var.prefix}-serverless-backend-neg"
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = var.cloud_run_name
  }
}

resource "google_compute_region_backend_service" "default" {
  name                            = "${var.prefix}-ilb-backend-dervice"
  region                          = var.region
  load_balancing_scheme           = "INTERNAL_MANAGED"
  port_name                       = "http"
  protocol                        = "HTTP"
  session_affinity                = "NONE"
  timeout_sec                     = var.timeout
  connection_draining_timeout_sec = 300

  backend {
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1
    group           = google_compute_region_network_endpoint_group.serverless_backend_neg.id
  }
}

resource "google_compute_forwarding_rule" "https" {
  region                = var.region
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  name                  = "${var.prefix}-ilb-https"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.default.id
  network               = var.network_id
  subnetwork            = google_compute_subnetwork.vault_ilb_backend_subnet.id
  network_tier          = "PREMIUM"

  depends_on = [google_compute_subnetwork.vault_ilb_frontend_subnet]
}

resource "google_compute_region_ssl_certificate" "default" {
  region = var.region
  name   = "${var.prefix}-ilb-certificate"

  certificate = file("cert.pem")
  private_key = file("private_key.pem")
}

resource "google_compute_region_target_https_proxy" "default" {
  name    = "${var.prefix}-ilb-https-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.default.id
  ssl_certificates = [
    google_compute_region_ssl_certificate.default.id
  ]
}

resource "google_compute_region_url_map" "default" {
  provider        = google-beta
  region          = var.region
  name            = "${var.prefix}-ilb-url-map"
  default_service = google_compute_region_backend_service.default.id
}
