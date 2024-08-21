locals {
  google_project_apis = [
    "sqladmin.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "deploymentmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "networkmanagement.googleapis.com",
    "sql-component.googleapis.com",
    "secretmanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "iam.googleapis.com",
    "cloudkms.googleapis.com"
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.google_project_apis)
  project  = var.project
  service  = each.key

  disable_dependent_services = false
  disable_on_destroy         = var.apis_disable_on_destroy
}
