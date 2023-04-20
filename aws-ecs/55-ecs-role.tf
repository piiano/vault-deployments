data "aws_arn" "db_password" {
  arn = aws_secretsmanager_secret.db_password.arn
}

resource "aws_iam_role" "pvault_ecs" {
  name = "${var.deployment_id}-ecs-role"


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

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"]

  inline_policy {
    name = "access_secrets_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "secretsmanager:GetSecretValue",
          ]
          Effect = "Allow"
          Resource = [
            "arn:${data.aws_arn.db_password.partition}:${data.aws_arn.db_password.service}:${data.aws_arn.db_password.region}:${data.aws_arn.db_password.account}:secret:/${var.deployment_id}/*"
          ]
        },
      ]
    })
  }

  inline_policy {
    name = "access_kms_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
          ]
          Effect = "Allow"
          Resource = [
            "${aws_kms_key.pvault.arn}"
          ]
        },
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = var.create_pvault_autoscaler ? { create_pvault_autoscaler = true } : {}

    content {
      name = "autoscaler_policy"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
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
            Effect = "Allow"
            Resource = [
              "*"
            ]
          },
        ]
      })
    }
  }
}
