
#################
### Cloud SQL ###
#################

locals {
  db_zone   = coalesce(var.cloudsql_zone, var.default_zone)
  db_region = coalesce(var.cloudsql_region, var.default_region)
}

module "postgresql-db" {
  source              = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version             = "15.0.0"
  name                = "${var.deployment_id}-${var.cloudsql_instance_name}"
  db_name             = var.cloudsql_name
  database_version    = var.cloudsql_version
  project_id          = var.project
  zone                = local.db_zone
  region              = local.db_region
  user_name           = var.cloudsql_username
  disk_autoresize     = true
  encryption_key_name = "${google_kms_crypto_key.db-encryption-key.key_ring}/cryptoKeys/${google_kms_crypto_key.db-encryption-key.name}"
  database_flags = [
    {
      name  = "max_connections"
      value = "100"
    }
  ]
  tier = var.cloudsql_tier

  deletion_protection = var.cloudsql_deletion_protection

  backup_configuration = {
    enabled                        = true
    start_time                     = "3:00" // save backup in 3 AM
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = "7"
    location                       = local.db_region
    retention_unit                 = "COUNT"
    retained_backups               = 7 // save backup for 7 days back
  }

  ip_configuration = {
    ipv4_enabled        = false
    private_network     = module.vpc.network_id
    allocated_ip_range  = null
    authorized_networks = []
    require_ssl         = false
  }

  create_timeout = "30m"
  update_timeout = "20m"

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.apis["sql-component.googleapis.com"]
  ]
}
