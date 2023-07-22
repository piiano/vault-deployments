
##############
### Locals ###
##############

locals {
  subnets = concat(
    [for subnet in var.subnets : merge(subnet, { subnet_region = coalesce(local.vault_region, var.default_region) })],
    [
      {
        subnet_name           = "${var.deployment_id}-${var.vault_cli_subnet}-${var.env}"
        subnet_region         = local.client_region
        subnet_ip             = var.vault_cli_subnet_range
        subnet_private_access = "true"
        description           = "Authorized subnet for accessing Vault Cloud Run"
      },
      {
        subnet_name           = "${var.deployment_id}-sb-connector-vault-cloud-run-${var.env}"
        subnet_ip             = var.vault_sql_serverless_connector_range
        subnet_region         = coalesce(local.vault_region, var.default_region)
        subnet_private_access = "true"
        description           = "Serverless Connector Subnet for Vault Cloud Run"
      },
      {
        subnet_name           = "${var.deployment_id}-sb-proxy-vault-connector-${var.env}"
        subnet_ip             = var.proxy_vault_serverless_connector_range
        subnet_region         = local.client_region
        subnet_private_access = "true"
        description           = "Serverless Connector Subnet for Proxy Cloud Run"
      }
    ]
  )
}

###############
### Network ###
###############

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 4.0"

  network_name                           = "${var.deployment_id}-${var.network}"
  routing_mode                           = "GLOBAL"
  project_id                             = var.project
  subnets                                = concat(local.subnets)
  routes                                 = var.routes
  firewall_rules                         = [
    for f in var.firewall : {
      name                    = "${var.deployment_id}-${f.name}"
      direction               = f.direction
      priority                = lookup(f, "priority", null)
      description             = lookup(f, "description", null)
      ranges                  = lookup(f, "ranges", null)
      source_tags             = lookup(f, "source_tags", null)
      source_service_accounts = lookup(f, "source_service_accounts", null)
      target_tags             = lookup(f, "target_tags", null)
      target_service_accounts = lookup(f, "target_service_accounts", null)
      allow                   = lookup(f, "allow", [])
      deny                    = lookup(f, "deny", [])
      log_config              = lookup(f, "log_config", null)
    }
  ]
  auto_create_subnetworks                = false
  delete_default_internet_gateway_routes = true

  depends_on = [google_project_service.apis]
}

##############################################
### Service Connection (Used by Cloud SQL) ###
##############################################

resource "google_compute_global_address" "private_ip_address" {
  name         = "${var.deployment_id}-${var.network}-ip-address"
  provider = google-beta
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"

  network       = module.vpc.network_id
  prefix_length = split("/", var.db_instance_ip_range)[1]
  address       = split("/", var.db_instance_ip_range)[0]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = module.vpc.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

################################################
### Serverless Connector (used by Cloud Run) ###
################################################

resource "google_project_service" "vpcaccess_api" {
  provider           = google-beta
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

resource "google_vpc_access_connector" "connector_vault_cloud_run" {
  name     = "${var.deployment_id}-sql-cn"
  provider = google-beta
  region   = local.vault_region
  subnet {
    name = module.vpc.subnets["${local.vault_region}/${var.deployment_id}-sb-connector-vault-cloud-run-${var.env}"].name
  }
  max_throughput = 400
  min_instances  = 2
  max_instances  = var.connector_cloud_run_max_instances
  depends_on     = [google_project_service.vpcaccess_api]
}

resource "google_vpc_access_connector" "proxy_vault_connector" {
  name     = "${var.deployment_id}-proxy-cn"
  provider = google-beta
  region   = local.client_region
  subnet {
    name = module.vpc.subnets["${local.client_region}/${var.deployment_id}-sb-proxy-vault-connector-${var.env}"].name
  }
  max_throughput = 400
  min_instances  = 2
  max_instances  = var.connector_cloud_run_max_instances
  depends_on     = [google_project_service.vpcaccess_api]
}
