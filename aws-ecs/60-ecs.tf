# Set up a log group to get container logs
resource "aws_cloudwatch_log_group" "pvault" {
  name = "/aws/ecs/${var.deployment_id}"
}

resource "aws_security_group" "service" {
  name   = "${var.deployment_id}-service"
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
    cidr_blocks = local.allowed_cidr_blocks
  }

  tags = {
    "Name" = "${var.deployment_id}_service"
  }
}



resource "aws_ecs_task_definition" "pvault" {
  family = "${var.deployment_id}-task"

  container_definitions = jsonencode(
    [
      {
        name       = "${var.deployment_id}-container",
        image      = "${var.pvault_repository}:${var.pvault_tag}",
        entryPoint = [],
        environment = concat([for k, v in var.pvault_env_vars : { "name" = k, "value" = v }], [
          { "name" : "PVAULT_DEVMODE", "value" : var.pvault_devmode ? "1" : "0" },
          { "name" : "PVAULT_DB_HOSTNAME", "value" : module.db.db_instance_address },
          { "name" : "PVAULT_DB_NAME", "value" : var.rds_db_name },
          { "name" : "PVAULT_DB_USER", "value" : var.rds_username },
          { "name" : "PVAULT_DB_PORT", "value" : var.rds_port },
          { "name" : "PVAULT_LOG_CUSTOMER_IDENTIFIER", "value" : var.pvault_log_customer_identifier },
          { "name" : "PVAULT_LOG_CUSTOMER_ENV", "value" : var.pvault_log_customer_env },
          { "name" : "PVAULT_KMS_URI", "value" : "aws-kms://${aws_kms_key.pvault.arn}" }
        ]),
        secrets = [
          { "name" : "PVAULT_DB_PASSWORD", "valueFrom" : aws_secretsmanager_secret.db_password.arn },
          { "name" : "PVAULT_SERVICE_LICENSE", "valueFrom" : aws_secretsmanager_secret.pvault_service_license.arn },
          { "name" : "PVAULT_SERVICE_ADMIN_API_KEY", "valueFrom" : aws_secretsmanager_secret.pvault_service_admin_api_key.arn }
        ],
        essential = true,
        logConfiguration = {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-group" : aws_cloudwatch_log_group.pvault.name,
            "awslogs-region" : var.aws_region,
            "awslogs-stream-prefix" : "pvault"
          }
        },
        portMappings = [
          {
            "containerPort" : 8123,
            "hostPort" : 8123,
            "protocol" : "tcp",
            "name" : "api"
          }
        ],
        healthCheck = {
          "command" : [
            "CMD-SHELL",
            "wget --spider localhost:8123/api/pvlt/1.0/ctl/info/health"
          ],
          "interval" : 15,
          "timeout" : 5,
          "retries" : 3
        },
        cpu         = 256,
        memory      = 512,
        networkMode = "awsvpc"
      }
    ]
  )

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.pvault_ecs.arn
  task_role_arn            = aws_iam_role.pvault_ecs.arn

}

module "ecs" {
  count = var.create_ecs_cluster ? 1 : 0

  source  = "terraform-aws-modules/ecs/aws"
  version = "4.1.3"

  cluster_name = "${var.deployment_id}-cluster"

  cluster_settings = {
    name  = "containerInsights"
    value = "enabled"
  }

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.pvault.name
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }
}

resource "aws_security_group" "alb" {
  name   = "${var.deployment_id}-alb"
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
    "Name" = "${var.deployment_id}_alb_sg"
  }
}

resource "aws_alb" "pvault" {
  name               = "${var.deployment_id}-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = local.private_subnet_ids
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name = "${var.deployment_id}-alb"
  }
}

resource "aws_lb_target_group" "pvault" {
  name        = "${var.deployment_id}-tg"
  port        = 8123
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/api/pvlt/1.0/ctl/info/health"
    unhealthy_threshold = "3"
  }

  tags = {
    Name = "${var.deployment_id}-lb-tg"
  }
}

resource "aws_lb_listener" "pvault" {
  load_balancer_arn = aws_alb.pvault.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pvault.id
  }
}

resource "aws_ecs_service" "pvault" {
  name            = var.deployment_id
  cluster         = one(module.ecs).cluster_id
  task_definition = aws_ecs_task_definition.pvault.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }

  network_configuration {
    subnets         = local.private_subnet_ids
    security_groups = [aws_security_group.alb.id]
  }

  load_balancer {
    container_name   = "${var.deployment_id}-container"
    container_port   = 8123
    target_group_arn = aws_lb_target_group.pvault.arn
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
