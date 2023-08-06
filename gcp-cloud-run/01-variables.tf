
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

variable "apis" {
  description = "List of APIs"
  type        = list(string)
  default = [
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

###############
### Network ###
###############
variable "network" {
  description = "VPC Network name"
  type        = string
  default     = "vpc-private-piiano"
}

variable "subnets" {
  type        = list(map(string))
  description = "List of subnets being created"

  default = []
}

variable "routes" {
  type        = list(map(string))
  description = "List of routes being created"

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
  description = "List of firewalls being created"

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

###########################
### Cloud Load Balancer ###
###########################

variable "client_region" {
  description = "Cloud Load Balancer. if empty fallback to default region"
  type        = string
}

variable "ilb_frontend_range" {
  description = "Cloud Load Balancer /26 CIDR range"
  type        = string
  default     = "10.8.1.0/26"
}

variable "ilb_backend_range" {
  description = "Cloud Load Balancer /26 CIDR range"
  type        = string
  default     = "10.8.0.64/26"
}

#############
### Proxy ###
#############
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

#################
### Cloud Run ###
#################

variable "vault_version" { default = "1.7.1" }

variable "vault_region" {
  description = "Vault Region. if empty fallback to default region"
  type        = string
}

variable "image" {
  description = "Vault server image name"
  type        = string
  default     = "us-central1-docker.pkg.dev/piiano/docker/pvault-server"
}

variable "vault_license" {
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

variable "vault_sql_serverless_connector_range" {
  description = "Cloud Run connector /28 CIDR range (used to connect Cloud Run to VPC)"
  type        = string
  default     = "10.8.0.0/28"
}

variable "connector_cloud_run_max_instances" {
  description = "Maximum number of instances used by VPC Serverless connector"
  type        = number
  default     = 4
}

########################
### Vault CLI Server ###
########################
variable "vault_cli_subnet" {
  description = "Subnet where Vault CLI will be deployed"
  type        = string
  default     = "sb-vault-authorized"
}

variable "vault_cli_subnet_range" {
  description = "Subnet CIDR range for the Vault CLI VM"
  type        = string
  default     = "10.8.0.16/28"
}

variable "vault_cli_zone" {
  description = "Zone where Vault CLI will be deployed"
  type        = string
  default     = null
}

variable "cli_image" {
  description = "Vault server image name"
  type        = string
  default     = "us-central1-docker.pkg.dev/piiano/docker/pvault-cli"
}

###########
### KMS ###
###########
variable "kms_ring_name" {
  description = "KMS Ring name"
  type        = string
  default     = "key-ring"
}

variable "vault_kms_key_name" {
  description = "KMS key name"
  type        = string
  default     = "vault-key"
}

variable "db_kms_key_name" {
  description = "KMS key name"
  type        = string
  default     = "db-key"
}

#################
### Cloud SQL ###
#################
variable "db_instance_name" {
  description = "Database instance name"
  type        = string
  default     = "vault-sql"
}

variable "db_name" {
  description = "Vault database name"
  type        = string
  default     = "pvault"
}

variable "db_version" {
  description = "Postgres database version"
  type        = string
  default     = "POSTGRES_14"
}

variable "db_zone" {
  description = "Database zone. if empty fallback to default zone"
  type        = string
  default     = null
}

variable "db_region" {
  description = "Database region. if empty fallback to default region"
  type        = string
  default     = null
}

variable "db_user" {
  description = "Vault database user"
  type        = string
  default     = "pvault"
}

variable "db_tier" {
  description = "Database instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_instance_ip_range" {
  description = "Database instance IP range"
  type        = string
  default     = "10.7.0.0/16"
}

variable "db_deletion_protection" {
  description = "Database instance deletion protection"
  type        = bool
  default     = false
}
