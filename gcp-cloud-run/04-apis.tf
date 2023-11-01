resource "google_project_service" "apis" {
  for_each = toset(var.apis)
  project  = var.project
  service  = each.key

  disable_dependent_services = false
  disable_on_destroy         = var.apis_disable_on_destroy
}
