locals {
  aux_kms_key = var.create_aux_kms_key == false && var.aux_kms_key_arn != "" ? var.aux_kms_key_arn : try(one(module.kms).key_arn, "")
}

provider "aws" {
  alias  = "auxregion"
  region = var.aws_aux_region
}

data "aws_caller_identity" "current" {}

module "kms" {
  count  = var.create_aux_kms_key && var.snapshot_replication_enabled ? 1 : 0
  
  source      = "terraform-aws-modules/kms/aws"
  version     = "~> 1.5"
  description = "KMS key for cross region automated backups replication"

  aliases                 = ["crossregion-rds-encryption"]
  aliases_use_name_prefix = true

  key_owners = [data.aws_caller_identity.current.arn]

  providers = {
    aws = aws.auxregion
  }
}

module "rds_db_instance_automated_backups_replication" {
  count  = var.snapshot_replication_enabled ? 1 : 0
  
  source  = "terraform-aws-modules/rds/aws//modules/db_instance_automated_backups_replication"
  version = "5.4.2"

  source_db_instance_arn = module.db.db_instance_arn
  kms_key_arn            = local.aux_kms_key
  
  providers = {
    aws = aws.auxregion
  }
}

###AWS Backup###
resource "aws_backup_plan" "pvault" {
  count  = var.backup_enabled ? 1 : 0
  
  name = "pvault-plan"

  rule {
    rule_name         = "pvault_example_backup_rule"
    target_vault_name = "Default"
    schedule          = "cron(0 12 * * ? *)"
  }
}

resource "aws_iam_role" "pvault_backup" {
  count  = var.backup_enabled ? 1 : 0
  
  name = "pvault-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pvault_backup" {
  count  = var.backup_enabled ? 1 : 0

  role       = one(aws_iam_role.pvault_backup).name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_selection" "pvault_rds_backup" {
  count  = var.backup_enabled ? 1 : 0

  name         = "pvault_rds"
  iam_role_arn = one(aws_iam_role.pvault_backup).arn
  plan_id      = one(aws_backup_plan.pvault).id

  resources = [
    module.db.db_instance_arn
  ]
}
