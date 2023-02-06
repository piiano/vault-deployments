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
          "kms:*",
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

# Only for autoscaling
resource "aws_iam_policy" "pvault_autoscale" {
  count = var.autoscaler_enabled ? 1 : 0
  
  name        = "vault-autoscale"
  description = "vault-autoscale policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "application-autoscaling:*",
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DisableAlarmActions",
          "cloudwatch:EnableAlarmActions",
          "iam:CreateServiceLinkedRole",
          "sns:CreateTopic",
          "sns:Subscribe",
          "sns:Get*",
          "sns:List*"
        ]
        Resource = [
          "*"
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

resource "aws_iam_role_policy_attachment" "pvault_ecs_autoscale" {
  count = var.autoscaler_enabled ? 1 : 0
  
  role       = aws_iam_role.pvault_ecs.name
  policy_arn = one(aws_iam_policy.pvault_autoscale).arn
}
