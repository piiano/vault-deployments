#################
### Cloud SQL ###
#################
module "postgresql-db" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "21.0.0"

  project_id = var.project
  zone       = local.db_zone
  region     = local.db_region

  name      = "${var.deployment_id}-vault-sql"
  db_name   = var.cloudsql_name
  user_name = var.cloudsql_username

  database_version    = local.db_version
  tier                = var.cloudsql_tier
  disk_autoresize     = true
  encryption_key_name = var.cloudsql_encryption_key_name

  database_flags = [
    {
      name  = "max_connections"
      value = "100"
    }
  ]

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
    private_network     = local.network
    allocated_ip_range  = null
    authorized_networks = []
    # https://cloud.google.com/sql/docs/postgres/admin-api/rest/v1/instances#sslmode
    ssl_mode = "ENCRYPTED_ONLY"
  }

  deletion_protection = var.cloudsql_deletion_protection

  create_timeout = "60m"
  update_timeout = "60m"

  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.apis["sql-component.googleapis.com"]
  ]
}
