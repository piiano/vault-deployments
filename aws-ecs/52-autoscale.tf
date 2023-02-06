locals {
  autoscaler_service_target = var.create_ecs_cluster == false && var.ecs_cluster_id != "" ? "service/${var.ecs_cluster_name}/pvault" : "service/pvault-ecs-fargate/pvault"
}

resource "aws_appautoscaling_target" "pvault_target" {
  count = var.autoscaler_enabled ? 1 : 0
  
  max_capacity = 5
  min_capacity = 1
  resource_id = local.autoscaler_service_target
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_average_cpu_50" {
  count = var.autoscaler_enabled ? 1 : 0
  
  name = "pvault-cpu-autoscale"
  policy_type = "TargetTrackingScaling"
  resource_id = one(aws_appautoscaling_target.pvault_target).resource_id
  scalable_dimension = one(aws_appautoscaling_target.pvault_target).scalable_dimension
  service_namespace = one(aws_appautoscaling_target.pvault_target).service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 50
  }
}
