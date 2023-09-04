
#################
### Cloud SQL ###
#################

locals {
  db_region = coalesce(var.db_region, var.default_region)
  db_zone   = coalesce(var.db_zone, var.default_zone)
}

module "postgresql-db" {
  source              = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version             = "15.0.0"
  name                = "${var.deployment_id}-${var.db_instance_name}"
  db_name             = var.db_name
  database_version    = var.db_version
  project_id          = var.project
  zone                = local.db_zone
  region              = local.db_region
  user_name           = var.db_user
  disk_autoresize     = true
  encryption_key_name = "${google_kms_crypto_key.db-encryption-key.key_ring}/cryptoKeys/${google_kms_crypto_key.db-encryption-key.name}"
  database_flags = [
    {
      name  = "max_connections"
      value = "100"
    }
  ]
  tier = var.db_tier

  deletion_protection = var.db_deletion_protection

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
