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
    # description = "pvault-secrets policy"
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
    # description = "pvault-kms policy"

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

  inline_policy {
    name = "vault-parameter-store"
    # description = "vault-parameter-store policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ssm:GetParameters"
          ]
          Resource = [
            "arn:${data.aws_arn.db_hostname.partition}:${data.aws_arn.db_hostname.service}:${data.aws_arn.db_hostname.region}:${data.aws_arn.db_hostname.account}:parameter/${var.deployment_id}/*"
          ]
        },
      ]
    })
  }

}

data "aws_arn" "db_password" {
  arn = aws_secretsmanager_secret.db_password.arn
}

# resource "aws_iam_policy" "pvault_secrets" {
#   name        = "pvault-secrets"
#   description = "pvault-secrets policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "secretsmanager:GetSecretValue",
#         ]
#         Resource = [
#           "arn:${data.aws_arn.db_password.partition}:${data.aws_arn.db_password.service}:${data.aws_arn.db_password.region}:${data.aws_arn.db_password.account}:secret:/pvault/*"
#         ]
#       },
#     ]
#   })
# }

# resource "aws_iam_policy" "pvault_kms" {
#   name        = "pvault-kms"
#   description = "pvault-kms policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "kms:*",
#         ]
#         Resource = [
#           "${aws_kms_key.pvault.arn}"
#         ]
#       },
#     ]
#   })
# }

data "aws_arn" "db_hostname" {
  arn = aws_ssm_parameter.db_hostname.arn
}

# resource "aws_iam_policy" "pvault_parameter_store" {

# }

# resource "aws_iam_role_policy_attachment" "pvault_secrets" {
#   role       = aws_iam_role.pvault.name
#   policy_arn = aws_iam_policy.pvault_secrets.arn
# }

# resource "aws_iam_role_policy_attachment" "pvault_kms" {
#   role       = aws_iam_role.pvault.name
#   policy_arn = aws_iam_policy.pvault_kms.arn
# }

# resource "aws_iam_role_policy_attachment" "pvault_parameter_store" {
#   role       = aws_iam_role.pvault.name
#   policy_arn = aws_iam_policy.pvault_parameter_store.arn
# }
