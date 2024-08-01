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

variable "create_ecs_cluster" {
  description = "Controls if a new AWS ECS Cluster should be created"
  type        = bool
  default     = true
}

variable "create_pvault_autoscaler" {
  description = "Controls if a service auto scaler should be created"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "The existing VPC_ID in case that `create_vpc` is false"
  type        = string
  default     = ""
}

variable "database_subnet_group_name" {
  description = "This parameter specifies the name of the subnet group to deploy the database"
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
  description = "The days to retain backups for the RDS"
  type        = number
  default     = 30
}

variable "pvault_repository" {
  description = "Pvault repository public image"
  type        = string
  default     = "piiano/pvault-server"
}

variable "pvault_tag" { default = "1.12.1" }

variable "pvault_port" {
  description = "Pvault application port number"
  type        = string
  default     = "8123"
}

variable "pvault_service_license" {
  description = "Pvault license code https://piiano.com/docs/guides/install/pre-built-docker-containers"
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
