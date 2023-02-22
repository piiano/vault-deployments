resource "aws_iam_role" "pvault" {
  name = "pvault-instance-role"
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
}

data "aws_arn" "db_password" {
  arn = aws_secretsmanager_secret.db_password.arn
}

resource "aws_iam_policy" "pvault_secrets" {
  name        = "pvault-secrets-${random_id.instance.hex}"
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
  name        = "pvault-kms-${random_id.instance.hex}"
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
  name        = "vault-parameter-store-${random_id.instance.hex}"
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

resource "aws_iam_role_policy_attachment" "pvault_secrets" {
  role       = aws_iam_role.pvault.name
  policy_arn = aws_iam_policy.pvault_secrets.arn
}

resource "aws_iam_role_policy_attachment" "pvault_kms" {
  role       = aws_iam_role.pvault.name
  policy_arn = aws_iam_policy.pvault_kms.arn
}

resource "aws_iam_role_policy_attachment" "pvault_parameter_store" {
  role       = aws_iam_role.pvault.name
  policy_arn = aws_iam_policy.pvault_parameter_store.arn
}
