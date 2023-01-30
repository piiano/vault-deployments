variable "aws_region" {
  description = "AWS region to deploy vault"
  type        = string
  default     = "us-east-2"
}

variable "create_vpc" {
  type    = bool
  default = true
}

variable "create_bastion" {
  type    = bool
  default = false
}

variable "vpc_id" {
  description = "The existing VPC_ID"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "The Private subnets where the Pvault will deploy"
  type        = list(string)
  default     = []
}

variable "database_subnet_ids" {
  description = "The Database subnets where the RDS will deploy"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "The subnets CIDRs which allowed to access the RDS"
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

variable "pvault_image" {
  description = "Pvault image:tag public image"
  type        = string
  default     = "public.ecr.aws/w6p8i1g8/pvault-server:1.1.3"
}

variable "pvault_port" {
  description = "Pvault application port number"
  type        = string
  default     = "8123"
}

variable "pvault_service_license" {
  description = "Pvault license code https://piiano.com/docs/guides/install/pre-built-docker-containers"
  type        = string
}

variable "create_client_bastion" {
  type    = bool
  default = true
}
