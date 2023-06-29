data "aws_availability_zones" "available" {}

module "vpc" {
  count = var.create_vpc ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name             = var.deployment_id
  cidr             = "10.0.0.0/16"
  azs              = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]

  # create_database_subnet_group = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

locals {
  vpc_id                     = var.create_vpc == false && var.vpc_id != "" ? var.vpc_id : one(module.vpc).vpc_id
  database_subnet_group_name = var.create_vpc == false && var.database_subnet_group_name != "" ? var.database_subnet_group_name : one(module.vpc).database_subnet_group_name
  private_subnet_ids         = var.create_vpc == false && var.private_subnet_ids != [] ? var.private_subnet_ids : one(module.vpc).private_subnets
  database_subnet_ids        = var.create_vpc == false && var.database_subnet_ids != [] ? var.database_subnet_ids : one(module.vpc).database_subnets
  allowed_cidr_blocks        = var.create_vpc == false && var.allowed_cidr_blocks != [] ? var.allowed_cidr_blocks : one(module.vpc).private_subnets_cidr_blocks
}


