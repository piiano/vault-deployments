resource "aws_security_group" "apprunner_endpoint" {
  name   = "apprunner-endpoint"
  vpc_id = local.vpc_id

  ingress {
    description = "Allow HTTPS to apprunner endpoint"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # cidr_blocks = module.vpc.private_subnets_cidr_blocks
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "apprunner_endpoint"
  }
}

resource "aws_vpc_endpoint" "apprunner_endpoint" {
  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.apprunner.requests"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnet_ids
  security_group_ids = [
    aws_security_group.apprunner_endpoint.id,
  ]
  tags = {
    "Name" = "apprunner_endpoint"
  }
}

resource "aws_security_group" "open" {
  name   = "open"
  vpc_id = local.vpc_id

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow all ingress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "open"
  }
}

# Allow the runner to access VPC resources - egress
resource "aws_apprunner_vpc_connector" "pvault" {
  vpc_connector_name = var.deployment_id
  subnets            = local.private_subnet_ids
  security_groups    = [aws_security_group.open.id]
}

resource "aws_apprunner_service" "pvault" {
  service_name = var.deployment_id

  instance_configuration {
    instance_role_arn = aws_iam_role.pvault.arn
  }

  source_configuration {
    auto_deployments_enabled = false
    image_repository {
      image_repository_type = "ECR_PUBLIC"
      image_identifier      = "${var.pvault_repository}:${var.pvault_tag}"
      image_configuration {
        port = var.pvault_port
        runtime_environment_variables = {
          PVAULT_DEVMODE                 = "1"
          PVAULT_DB_HOSTNAME             = module.db.db_instance_address
          PVAULT_DB_NAME                 = var.rds_db_name
          PVAULT_DB_USER                 = var.rds_username
          PVAULT_DB_PORT                 = var.rds_port
          PVAULT_LOG_CUSTOMER_IDENTIFIER = var.pvault_log_customer_identifier
          PVAULT_LOG_CUSTOMER_ENV        = var.pvault_log_customer_env
          PVAULT_KMS_URI                 = "aws-kms://${aws_kms_key.pvault.arn}"
        }
        runtime_environment_secrets = {
          PVAULT_DB_PASSWORD           = aws_secretsmanager_secret.db_password.arn
          PVAULT_SERVICE_LICENSE       = aws_secretsmanager_secret.pvault_service_license.arn
          PVAULT_SERVICE_ADMIN_API_KEY = aws_secretsmanager_secret.pvault_service_admin_api_key.arn
        }
      }
    }
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.pvault.arn
    }
    ingress_configuration {
      is_publicly_accessible = var.is_publically_accessible
    }
  }

  health_check_configuration {
    healthy_threshold   = 3
    interval            = 15
    path                = "/api/pvlt/1.0/ctl/info/health"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
}

# Allow ingress to service from VPC Only
resource "aws_apprunner_vpc_ingress_connection" "pvault" {
  count = var.is_publically_accessible ? 0 : 1

  name        = var.deployment_id
  service_arn = aws_apprunner_service.pvault.arn

  ingress_vpc_configuration {
    vpc_id          = local.vpc_id
    vpc_endpoint_id = aws_vpc_endpoint.apprunner_endpoint.id
  }

  depends_on = [
    aws_apprunner_service.pvault
  ]
}



