resource "aws_kms_key" "pvault" {
  description             = "pvault key"
  deletion_window_in_days = 7
  tags = {
    Name = "pvault"
  }
}

resource "aws_kms_alias" "pvault" {
  name          = "alias/pvault"
  target_key_id = aws_kms_key.pvault.key_id
}
