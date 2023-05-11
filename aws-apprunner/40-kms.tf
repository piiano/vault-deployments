resource "aws_kms_key" "pvault" {
  description             = "pvault key"
  deletion_window_in_days = 7
  tags = {
    Name = var.deployment_id
  }
}

resource "aws_kms_alias" "pvault" {
  name          = "alias/${var.deployment_id}"
  target_key_id = aws_kms_key.pvault.key_id
}
