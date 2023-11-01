
###############
### General ###
###############

variable "project" {
  description = "GCP Project ID where resources will be deployed"
  type        = string
}

variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "deployment_id" {
  description = "The unique deployment id of this deployment"
  type        = string
}

variable "default_region" {
  description = "Default region where resources without a specified region will be deployed"
  type        = string
  default     = "us-central1"
}

variable "default_zone" {
  description = "Default zone where resources without a specified zone will be deployed"
  type        = string
  default     = "us-central1-a"
}

variable "apis_disable_on_destroy" {
  description = "Disable APIs on destroy"
  type        = bool
  default     = false
}

###############
### Network ###
###############

variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "The existing VPC_ID in case that `create_vpc` is false"
  type        = string
  default     = null
}

variable "vault_cn_subnet_name" {
  description = "Vault connector subnet name in the vpc in case that `create_vpc` is false"
  type        = string
  default     = null
}

variable "bastion_subnet_name" {
  description = "Bastion subnet name in the vpc in case that `create_vpc` is false"
  type        = string
  default     = null
}

variable "subnets" {
  type        = list(map(string))
  description = "List of subnets to be created when `create_vpc` is true"

  default = []
}

variable "routes" {
  type        = list(map(string))
  description = "List of routes to be created when `create_vpc` is true"

  default = [
    {
      name              = "rt-egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      next_hop_internet = "true"
    }
  ]
}

variable "firewall" {
  type        = any
  description = "List of firewalls to be created when `create_vpc` is true"

  default = [
    {
      name      = "fw-allow-ssh-ingress-vpc-private-piiano"
      direction = "INGRESS"
      ranges    = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    }
  ]
}

#################
### Cloud Run ###
#################

# leave the following in a single line - publish workflow relies on it
variable "pvault_tag" { default = "1.9.0" }

variable "pvault_region" {
  description = "Vault Region. if empty fallback to default region"
  type        = string
  default     = null
}

variable "pvault_repository" {
  description = "Vault Server container repository"
  type        = string
  default     = "us-central1-docker.pkg.dev/piiano/docker/pvault-server"
}

variable "pvault_service_license" {
  description = "Vault server license token"
  type        = string
}

variable "pvault_log_customer_identifier" {
  description = "Identifies the customer in all the observability platforms"
  type        = string
}

variable "pvault_log_customer_env" {
  description = "Identifies the environment in all the observability platforms. Recommended values are PRODUCTION, STAGING, and DEV"
  type        = string
}

variable "pvault_sql_serverless_connector_range" {
  description = "Cloud Run connector /28 CIDR range (used to connect Cloud Run to VPC)"
  type        = string
  default     = "10.8.0.0/28"
}

variable "pvault_devmode" {
  description = "Enable devmode for Pvault. See https://piiano.com/docs/guides/configure/environment-variables#production-and-development-mode for more details."
  type        = bool
  default     = false
}

variable "pvault_env_vars" {
  description = "A map of environment variables and values to set for the Pvault service. Except the following: PVAULT_LOG_CUSTOMER_IDENTIFIER, PVAULT_LOG_CUSTOMER_ENV, PVAULT_TLS_ENABLE, PVAULT_DB_REQUIRE_TLS, PVAULT_DB_HOSTNAME, PVAULT_DB_NAME, PVAULT_DB_USER, PVAULT_SERVICE_LICENSE, PVAULT_SERVICE_TIMEOUT_SECONDS, PVAULT_KMS_URI, PVAULT_DEVMODE, PVAULT_DB_PASSWORD, PVAULT_SERVICE_ADMIN_API_KEY. See [https://piiano.com/docs/guides/configure/environment-variables](https://piiano.com/docs/guides/configure/environment-variables) for more details."
  type        = map(string)
  default     = {
    # Add environment variables as needed, for example:
    # PVAULT_FEATURES_MASK_LICENSE = true
  }
}

variable "connector_cloud_run_max_instances" {
  description = "Maximum number of instances used by VPC Serverless connector"
  type        = number
  default     = 4
}

###########################
### Cloud Load Balancer ###
###########################

variable "client_region" {
  description = "Client region for cloud load balancer. applicable when create_proxy = true. if empty fallback to default region"
  type        = string
  default     = null
}

variable "ilb_frontend_range" {
  description = "Frontend range for cloud load balancer. applicable when create_proxy = true. /26 CIDR range"
  type        = string
  default     = "10.8.1.0/26"
}

variable "ilb_backend_range" {
  description = "Backend range for cloud load balancer. applicable when create_proxy = true. /26 CIDR range"
  type        = string
  default     = "10.8.0.64/26"
}

#############
### Proxy ###
#############

variable "create_proxy" {
    description = "Controls if proxy resources should be created. See readme for more details on deployment modes [https://github.com/piiano/vault-deployments/blob/main/gcp-cloud-run/README.md#solution-architecture](https://github.com/piiano/vault-deployments/blob/main/gcp-cloud-run/README.md#solution-architecture) for more details."
    type        = bool
    default     = false
}

variable "proxy_vault_serverless_connector_range" {
  description = "Cloud Run connector /28 CIDR range (used to connect Cloud Run to VPC)"
  type        = string
  default     = "10.8.3.0/28"
}

variable "proxy_image" {
  description = "Proxy Docker image"
  type        = string
  default     = "us-central1-docker.pkg.dev/piiano/docker/nginx-proxy:3"
}

#####################
### Vault bastion ###
#####################

variable "create_bastion" {
  description = "Controls if bastion resources should be created"
  type        = bool
  default     = true
}

variable "pvault_bastion_subnet" {
  description = "Subnet where Vault bastion will be deployed"
  type        = string
  default     = "sb-vault-authorized"
}

variable "pvault_bastion_subnet_range" {
  description = "Subnet CIDR range for the Vault bastion VM"
  type        = string
  default     = "10.8.0.16/28"
}

variable "pvault_bastion_zone" {
  description = "Zone where Vault bastion will be deployed"
  type        = string
  default     = null
}

variable "pvault_cli_repository" {
  description = "Vault CLI repository name"
  type        = string
  default     = "us-central1-docker.pkg.dev/piiano/docker/pvault-cli"
}

#################
### Cloud SQL ###
#################

variable "cloudsql_name" {
  description = "Vault cloud sql name"
  type        = string
  default     = "pvault"
}

variable "cloudsql_zone" {
  description = "Vault cloud sql zone. if empty fallback to default zone"
  type        = string
  default     = null
}

variable "cloudsql_region" {
  description = "Vault cloud sql region. if empty fallback to default region"
  type        = string
  default     = null
}

variable "cloudsql_username" {
  description = "Vault cloud sql user name"
  type        = string
  default     = "pvault"
}

variable "cloudsql_tier" {
  description = "Cloud sql instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "cloudsql_instance_ip_range" {
  description = "Cloud sql instance IP range"
  type        = string
  default     = "10.7.0.0/16"
}

variable "cloudsql_deletion_protection" {
  description = "Cloud sql instance deletion protection"
  type        = bool
  default     = false
}
