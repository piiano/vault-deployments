data "aws_arn" "db_password" {
  arn = aws_secretsmanager_secret.db_password.arn
}

resource "aws_iam_role" "pvault" {
  name = "${var.deployment_id}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "pvault-secrets"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
          ]
          Resource = [
            "arn:${data.aws_arn.db_password.partition}:${data.aws_arn.db_password.service}:${data.aws_arn.db_password.region}:${data.aws_arn.db_password.account}:secret:/${var.deployment_id}/*"
          ]
        },
      ]
    })
  }

  inline_policy {
    name = "pvault-kms"

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
}
