resource "aws_kms_key" "pvault" {
  description             = "${var.deployment_id} key"
  deletion_window_in_days = 30
  tags = {
    Name = "${var.deployment_id}"
  }
}

