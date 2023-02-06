resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = local.vpc_id

  ingress {
    description = "Allow postgress ingress from private subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.allowed_cidr_blocks
  }

  tags = {
    "Name" = "rds_sg"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "pvault"
  subnet_ids = local.database_subnet_ids

  tags = {
    Name = "pvault_subnet_group"
  }
}


module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "5.2.3"

  identifier = "pvault"

  engine               = "postgres"
  engine_version       = "14.5"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group

  # Network
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false

  # Sizing
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage

  # Access
  db_name  = var.rds_db_name
  username = var.rds_username
  port     = var.rds_port

  # Backups
  backup_retention_period = 7

  # Tuning
  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  tags = {
    "Name" = "pvault"
  }
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "/pvault/db_password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = module.db.db_instance_password
}

resource "aws_ssm_parameter" "db_hostname" {
  name  = "/pvault/db_hostname"
  type  = "String"
  value = module.db.db_instance_address
}
