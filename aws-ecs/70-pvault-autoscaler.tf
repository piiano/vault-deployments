resource "aws_iam_policy" "pvault_autoscaler" {
  count = var.create_pvault_autoscaler ? 1 : 0

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


resource "aws_iam_role_policy_attachment" "pvault_autoscaler" {
  count = var.create_pvault_autoscaler ? 1 : 0

  role       = aws_iam_role.pvault_ecs.name
  policy_arn = one(aws_iam_policy.pvault_autoscaler).arn
}

resource "aws_appautoscaling_target" "pvault_target" {
  count = var.create_pvault_autoscaler ? 1 : 0

  max_capacity       = 5
  min_capacity       = 1
  resource_id        = "service/pvault-ecs-fargate/pvault"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on         = [aws_ecs_service.pvault]
}


resource "aws_appautoscaling_policy" "ecs_average_cpu_50" {
  count = var.create_pvault_autoscaler ? 1 : 0

  name               = "pvault-cpu-autoscale"
  policy_type        = "TargetTrackingScaling"
  resource_id        = one(aws_appautoscaling_target.pvault_target).resource_id
  scalable_dimension = one(aws_appautoscaling_target.pvault_target).scalable_dimension
  service_namespace  = one(aws_appautoscaling_target.pvault_target).service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 50
  }
  depends_on = [aws_ecs_service.pvault]
}
