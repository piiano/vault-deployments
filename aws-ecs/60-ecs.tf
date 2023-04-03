resource "aws_iam_role" "pvault_ecs" {
  name = "pvault-ecs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_arn" "db_password" {
  arn = aws_secretsmanager_secret.db_password.arn
}

resource "aws_iam_policy" "pvault_secrets" {
  name        = "pvault-secrets"
  description = "pvault-secrets policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = [
          "arn:${data.aws_arn.db_password.partition}:${data.aws_arn.db_password.service}:${data.aws_arn.db_password.region}:${data.aws_arn.db_password.account}:secret:/pvault/*"
        ]
      },
    ]
  })
}

resource "aws_iam_policy" "pvault_kms" {
  name        = "pvault-kms"
  description = "pvault-kms policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
        ]
        Resource = [
          "${aws_kms_key.pvault.arn}"
        ]
      },
    ]
  })
}

data "aws_arn" "db_hostname" {
  arn = aws_ssm_parameter.db_hostname.arn
}

resource "aws_iam_policy" "pvault_parameter_store" {
  name        = "vault-parameter-store"
  description = "vault-parameter-store policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:${data.aws_arn.db_hostname.partition}:${data.aws_arn.db_hostname.service}:${data.aws_arn.db_hostname.region}:${data.aws_arn.db_hostname.account}:parameter/pvault/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pvault_ecs_secrets" {
  role       = aws_iam_role.pvault_ecs.name
  policy_arn = aws_iam_policy.pvault_secrets.arn
}

resource "aws_iam_role_policy_attachment" "pvault_ecs_kms" {
  role       = aws_iam_role.pvault_ecs.name
  policy_arn = aws_iam_policy.pvault_kms.arn
}

resource "aws_iam_role_policy_attachment" "pvault_ecs_parameter_store" {
  role       = aws_iam_role.pvault_ecs.name
  policy_arn = aws_iam_policy.pvault_parameter_store.arn
}

resource "aws_iam_role_policy_attachment" "pvault_ecs_container_service" {
  role       = aws_iam_role.pvault_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


# Set up a log group to get container logs
resource "aws_cloudwatch_log_group" "pvault" {
  name = "/aws/ecs/pvault-logs"
}

module "ecs" {
  count = var.create_ecs_cluster ? 1 : 0

  source  = "terraform-aws-modules/ecs/aws"
  version = "4.1.3"

  cluster_name = "pvault-ecs-fargate"

  cluster_settings = {
    name  = "containerInsights"
    value = "enabled"
  }

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/pvault-logs"
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


resource "aws_ecs_task_definition" "pvault" {
  family = "pvault-task"

  container_definitions = <<EOF
  [
    {
      "name": "pvault-container",
      "image": "${var.pvault_image}",
      "entryPoint": [],
      "environment": [
        {"name": "PVAULT_DEVMODE", "value": "1"},
        {"name": "PVAULT_DB_HOSTNAME", "value": "${module.db.db_instance_address}"},
        {"name": "PVAULT_DB_NAME", "value": "${var.rds_db_name}"},
        {"name": "PVAULT_DB_USER", "value": "${var.rds_username}"},
        {"name": "PVAULT_DB_PORT", "value": "${var.rds_port}"},
        {"name": "PVAULT_LOG_CUSTOMER_IDENTIFIER", "value": "${var.pvault_log_customer_identifier}"},
        {"name": "PVAULT_LOG_CUSTOMER_ENV", "value": "${var.pvault_log_customer_env}"},
        {"name": "PVAULT_KMS_URI", "value": "aws-kms://${aws_kms_key.pvault.arn}"}
      ],
      "secrets": [
        {"name": "PVAULT_DB_PASSWORD", "valueFrom": "${aws_secretsmanager_secret.db_password.arn}"},
        {"name": "PVAULT_SERVICE_LICENSE", "valueFrom": "${aws_secretsmanager_secret.pvault_service_license.arn}"},
        {"name": "PVAULT_SERVICE_ADMIN_API_KEY", "valueFrom": "${aws_secretsmanager_secret.pvault_service_admin_api_key.arn}"}
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.pvault.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "pvault"
        }
      },
      "portMappings": [
        {
          "containerPort": 8123,
          "hostPort": 8123,
          "protocol": "tcp",
          "name": "api"
        }
      ],
      "healthCheck": {
          "command": [
              "CMD-SHELL",
	        "wget --spider localhost:8123/api/pvlt/1.0/ctl/info/health"
          ],
          "interval": 15,
          "timeout": 5,
          "retries": 3
      },
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  EOF

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.pvault_ecs.arn
  task_role_arn            = aws_iam_role.pvault_ecs.arn

}


resource "aws_security_group" "open" {
  name   = "open-sg"
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
    "Name" = "open_sg"
  }
}


resource "aws_alb" "pvault" {
  name               = "pvault-ecs-alb"
  internal           = true
  load_balancer_type = "application"
  subnets            = local.private_subnet_ids
  security_groups    = [aws_security_group.open.id]

  tags = {
    Name = "pvault-alb"
  }
}

resource "aws_lb_target_group" "pvault" {
  name        = "pvault-tg"
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
    Name = "pvault-lb-tg"
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
  name            = "pvault"
  cluster         = "pvault-ecs-fargate"
  task_definition = aws_ecs_task_definition.pvault.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
  }

  network_configuration {
    subnets         = local.private_subnet_ids
    security_groups = [aws_security_group.open.id]
  }

  load_balancer {
    container_name   = "pvault-container"
    container_port   = 8123
    target_group_arn = aws_lb_target_group.pvault.arn
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
