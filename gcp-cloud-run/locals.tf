locals {
  pvault_region           = coalesce(var.pvault_region, var.default_region)
  pvault_db_socket_folder = "/cloudsql"

  # Admin API key
  pvault_admin_api_key_generate         = var.pvault_admin_api_key.secret_id == null
  pvault_admin_api_key_rotation_enabled = var.pvault_admin_api_key.rotate_days > 0 && local.pvault_admin_api_key_generate
  pvault_admin_api_key_secret           = local.pvault_admin_api_key_generate ? google_secret_manager_secret.admin_api_key[0] : data.google_secret_manager_secret.admin_api_key[0]

  # Generate env variables
  pvault_env = merge(
    {
      PVAULT_LOG_CUSTOMER_IDENTIFIER = var.pvault_log_customer_identifier
      PVAULT_LOG_CUSTOMER_ENV        = var.pvault_log_customer_env
      PVAULT_LOG_CUSTOMER_REGION     = var.pvault_region
      PVAULT_TLS_ENABLE              = "false"
      PVAULT_DB_REQUIRE_TLS          = "false"
      PVAULT_DB_HOSTNAME             = "${local.pvault_db_socket_folder}/${module.postgresql-db.instance_connection_name}"
      PVAULT_DB_NAME                 = var.cloudsql_name
      PVAULT_DB_USER                 = var.cloudsql_username
      PVAULT_SERVICE_LICENSE         = var.pvault_service_license
      PVAULT_KMS_URI                 = "gcp-kms://${google_kms_crypto_key.vault-encryption-key.key_ring}/cryptoKeys/${google_kms_crypto_key.vault-encryption-key.name}"
      PVAULT_DEVMODE                 = tostring(var.pvault_devmode)
      # Update API key on restart
      PVAULT_SERVICE_OVERRIDE_ADMIN_API_KEY_ON_RESTART = local.pvault_admin_api_key_rotation_enabled || !local.pvault_admin_api_key_generate
    },
    var.pvault_env_vars,
  )

  # DB
  db_version = "POSTGRES_15"
  db_region  = coalesce(var.cloudsql_region, var.default_region)
  db_zone    = coalesce(var.cloudsql_zone, var.default_zone, data.google_compute_zones.db_zones.names[0])

  # Bastion
  vault_bastion_zone               = coalesce(var.pvault_bastion_zone, var.default_zone, data.google_compute_zones.default_zones.names[0])
  vault_url                        = var.create_proxy ? google_cloud_run_v2_service.nginx_proxy[0].uri : google_cloud_run_v2_service.pvault-server.uri
  service_account_access_token_url = "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"
  admin_key_secret_url             = "https://secretmanager.googleapis.com/v1/${local.pvault_admin_api_key_secret.id}/versions/latest:access"
  bastion_subnetwork               = var.create_vpc ? module.vpc[0].subnets["${local.client_region}/${var.deployment_id}-${var.pvault_bastion_subnet}-${var.env}"].id : var.bastion_subnet_name

  # KMS
  kms_ring_name = "key-ring"

  # Proxy
  client_region = coalesce(
    var.client_region,
    var.pvault_region,
    var.default_region,
  )
}
