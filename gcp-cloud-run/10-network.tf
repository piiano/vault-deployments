
##############
### Locals ###
##############

locals {
  network = var.create_vpc ? module.vpc[0].network_id : var.vpc_id

  subnets = concat(
    var.create_vpc ? [for subnet in var.subnets : merge(subnet, {
      subnet_name = "${var.deployment_id}-${subnet.subnet_name}-${var.env}"
      subnet_region = coalesce(local.pvault_region, var.default_region),
    })] : [],
    var.create_vpc ? [
      {
        subnet_name           = "${var.deployment_id}-${var.pvault_bastion_subnet}-${var.env}"
        subnet_ip             = var.pvault_bastion_subnet_range
        subnet_region         = local.client_region
        subnet_private_access = "true"
        description           = "Authorized subnet for accessing Vault Cloud Run"
      },
      {
        subnet_name           = "${var.deployment_id}-sb-connector-vault-cloud-run-${var.env}"
        subnet_ip             = var.pvault_sql_serverless_connector_range
        subnet_region         = coalesce(local.pvault_region, var.default_region)
        subnet_private_access = "true"
        description           = "Serverless Connector Subnet for Vault Cloud Run"
      }
    ] : [],
    var.create_proxy ? [
      {
        subnet_name           = "${var.deployment_id}-sb-proxy-vault-connector-${var.env}"
        subnet_ip             = var.proxy_vault_serverless_connector_range
        subnet_region         = local.client_region
        subnet_private_access = "true"
        description           = "Serverless Connector Subnet for Proxy Cloud Run"
      }
    ] : []
  )

  vault_cn_subnet = var.create_vpc ? module.vpc[0].subnets["${local.pvault_region}/${var.deployment_id}-sb-connector-vault-cloud-run-${var.env}"].name : var.vault_cn_subnet_name
  proxy_cn_subnet = var.create_vpc && var.create_proxy ? module.vpc[0].subnets["${local.client_region}/${var.deployment_id}-sb-proxy-vault-connector-${var.env}"].name : null
}

###############
### Network ###
###############

module "vpc" {
  count = var.create_vpc ? 1 : 0

  source  = "terraform-google-modules/network/google"
  version = "~> 4.0"

  network_name                           = "${var.deployment_id}-vpc-private-piiano"
  routing_mode                           = "GLOBAL"
  project_id                             = var.project
  subnets                                = local.subnets
  routes                                 = [
    for r in var.routes : {
      name              = "${var.deployment_id}-${r.name}"
      description       = lookup(r, "description", null)
      destination_range = lookup(r, "destination_range", null)
      next_hop_internet = lookup(r, "next_hop_internet", null)
    }
  ]
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
  name         = "${var.deployment_id}-vpc-private-piiano-ip-address"
  provider = google-beta
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"

  network       = local.network
  prefix_length = split("/", var.cloudsql_instance_ip_range)[1]
  address       = split("/", var.cloudsql_instance_ip_range)[0]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = local.network
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
  region   = local.pvault_region
  subnet {
    name = local.vault_cn_subnet
  }
  max_throughput = 400
  min_instances  = 2
  max_instances  = var.connector_cloud_run_max_instances
  depends_on     = [google_project_service.vpcaccess_api]
}

resource "google_vpc_access_connector" "proxy_vault_connector" {
  count = var.create_proxy ? 1 : 0

  name     = "${var.deployment_id}-proxy-cn"
  provider = google-beta
  region   = local.client_region
  subnet {
    name = local.proxy_cn_subnet
  }
  max_throughput = 400
  min_instances  = 2
  max_instances  = var.connector_cloud_run_max_instances
  depends_on     = [google_project_service.vpcaccess_api]
}
