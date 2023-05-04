resource "aws_appautoscaling_target" "pvault_target" {
  count = var.create_pvault_autoscaler ? 1 : 0

  min_capacity       = 1
  max_capacity       = 5
  resource_id        = "service/${one(module.ecs).cluster_id}/${aws_ecs_service.pvault.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
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
}
