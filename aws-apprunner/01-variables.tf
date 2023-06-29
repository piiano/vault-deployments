variable "aws_region" {
  description = "AWS region to deploy vault"
  type        = string
  default     = "us-east-2"
}

variable "deployment_id" {
  description = "The unique deployment id of this deployment"
  type        = string
  default     = "pvault"
}

variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
  default     = true
}

variable "create_bastion" {
  description = "Controls if a new EC2 bastion should be created in VPC"
  type        = bool
  default     = false
}

variable "is_publically_accessible" {
  description = "Controls if the Pvault service should be publically accessible"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "The existing VPC_ID in case that `create_vpc` is false"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets where the Pvault service will deploy"
  type        = list(string)
  default     = []
}

variable "database_subnet_ids" {
  description = "The IDs if the Database subnets where the RDS will deploy"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "The subnets CIDRs which allowed to access the Pvault service"
  type        = list(string)
  default     = []
}

variable "rds_instance_class" {
  description = "Pvault RDS instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "rds_allocated_storage" {
  description = "Pvault RDS initial allocated storage in GB"
  type        = number
  default     = "20"
}

variable "rds_db_name" {
  description = "Pvault RDS database name"
  type        = string
  default     = "pvault"
}

variable "rds_username" {
  description = "Pvault RDS username"
  type        = string
  default     = "pvault"
}

variable "rds_port" {
  description = "Pvault RDS port"
  type        = string
  default     = "5432"
}

variable "rds_backup_retention_period" {
  description = "The days to retain backups for RDS. Possible values are 0-35"
  validation {
    condition     = var.rds_backup_retention_period >= 1 && var.rds_backup_retention_period <= 35
    error_message = "rds_backup_retention_period must be a numbert between 1 and 35"
  }
  type     = string
  nullable = false
  default  = 7
}

variable "pvault_repository" {
  description = "Pvault repository public image"
  type        = string
  default     = "public.ecr.aws/s4s5s6q8/pvault-server"
}

variable "pvault_tag" { default = "1.6.2" }
variable "pvault_port" {
  description = "Pvault application port number"
  type        = string
  default     = "8123"
}

variable "pvault_log_customer_identifier" {
  description = "Identifies the customer in all the observability platforms"
  type        = string
}

variable "pvault_log_customer_env" {
  description = "Identifies the environment in all the observability platforms. Recommended values are PRODUCTION, STAGING, and DEV"
  type        = string
}

variable "create_client_bastion" {
  type    = bool
  default = true
}

variable "create_secret_license" {
  description = "Controls if the secret license should be created. If set to 'false', var.secret_arn_license must be set"
  type        = bool
  default     = true
}

variable "secret_arn_license" {
  description = "The ARN of the Secrets Manager secret of Pvault license. If var.create_secret_license is set to 'true', this variable is ignored"
  type        = string
  sensitive   = true
  default     = ""
}

variable "pvault_service_license" {
  description = "Pvault license code https://piiano.com/docs/guides/install/pre-built-docker-containers. Cannot be set if var.create_secret_license is set to 'true'"
  type        = string
  sensitive   = true
  default     = ""
}

variable "instance_cpu" {
  description = "The number of CPU units for the Pvault instance. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_service#instance-configuration for more details."
  type        = number
  default     = 1024
}

variable "instance_memory" {
  description = "The amount of memory in MiB for the Pvault instance. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_service#instance-configuration for more details."
  type        = number
  default     = 2048
}

variable "pvault_devmode" {
  description = "Enable devmode for Pvault. See https://piiano.com/docs/guides/configure/environment-variables#production-and-development-mode for more details."
  type        = bool
  default     = false
}

variable "pvault_admin_may_read_data" {
  description = "Whether Admin is allowed to read data. See https://piiano.com/docs/guides/configure/environment-variables#service-and-features for more details."
  type        = bool
  default     = false
}

variable "pvault_env_vars" {
  description = "A map of environment variables to set for the Pvault service. See https://piiano.com/docs/guides/configure/environment-variables for more details."
  type        = map(string)
  default     = {}
}

locals {
  # Validation: Either you let the module create the secret or you provide the ARN of an existing secret.
  # tflint-ignore: terraform_unused_declarations
  collision_license = (
    (length(var.secret_arn_license) > 0 && length(var.pvault_service_license) > 0) ||
    (length(var.secret_arn_license) == 0 && length(var.pvault_service_license) == 0)
  ) ? tobool("Exactly one of var.secret_arn_license and var.pvault_service_license must be set") : true
}

# (variable "pvault_tag" {[^}]*default\s*=\s*")([^"]*)
