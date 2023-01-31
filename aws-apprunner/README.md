# Terraform for Piiano Vault AWS App Runner

This module deploys Piiano Vault on a given AWS region. It will outputs the private Vault URL post deployment.

## Solution Architecture

Vault is deployed as a single App Runner regional service. The service is deployed in the App Runner VPC and is configured for private access only from the `client-vpc`.
Internally, Vault communicates with a Postgres RDS that resides in the `pvault-vpc` (database subnet).

![piiano-vault](piiano-vault-aws-apprunner.png "terraform-piiano-vault-apprunner")

## Installed Components

The following components are installed by default (some are optional):

| Name          | Description                                   | Remarks                                                     |
| ------------- | --------------------------------------------- | ----------------------------------------------------------- |
| VPC           | 3 subnets \* 2 Availability zone              | Optional - Can be replaced with existing VPC parameters     |
| Bastion       | bastion EC2 instance                          | Optional - For testing purpose. Created in the `pvault-vpc` |
| RDS           | AWS Managed Postgres instance                 |                                                             |
| Secrets       | AWS Secret manager                            |                                                             |
| Parameters    | AWS parameter store                           |                                                             |
| Instance-role | IAM Instance role for the app runner instance |                                                             |
| VPC endpoint  | Private VPC Endpoint for App Runner           |                                                             |
| App runner    | Managed App Runner deployment of Piiano Vault |                                                             |

## Use cases

The terraform parameters can be overridden by updating the .tfvars file or by configuring an equivalent environment variable: `export TF_VAR_<variable name>=<new value>`.

1. With the default parameters - create a new VPC without a bastion for testing. To install the bastion, change the `create_bastion` variable to `true`.
2. To reuse your existing VPC, disable the creation by setting `create_vpc` to `false` and configure the parameter for `vpc_id`. You can find your VPC ID in the AWS console. It is also required to configure your existing subnets with these variables: `private_subnet_ids`, `database_subnet_ids`, `allowed_cidr_blocks`.

## Prerequisites

1. A valid license - Click register to [obtain your license](https://piiano.com/docs/guides/get-started). Update it in .tfvars file or configure the environment variable `export TF_VAR_pvault_service_license=<the license>`
2. AWS administrative role for the target account.

## Usage

```hcl
module "pvault" {
  source               = "./modules/piiano-vault-apprunner"
  pvault_service_license = "eyJhbGc..."
}
```

### Installation

```
terraform init
terraform apply
```

### Post installation

When a successful installation completes, it shows the following output:

```
authtoken = "Secret Manager: /pvault/pvault_service_admin_api_key --> retrieve value"
vault_url = "https://<random dns>.<region>.awsapprunner.com"
```

To check that the Vault is working as expected run the following from inside the application VPC. By default the script deploys a bastion machine that could be used for that purpose:

```
alias pvault="docker run --rm -i -v $(pwd):/pwd -w /pwd piiano/pvault-cli:1.1.3"
pvault --addr <VAULT URL from above> --authtoken '<token from the secret manager>' selftest basic
```

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                   | Version |
| ------------------------------------------------------ | ------- |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | >= 4.51 |

## Providers

| Name                                                      | Version |
| --------------------------------------------------------- | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws)          | 4.52.0  |
| <a name="provider_random"></a> [random](#provider_random) | 3.4.3   |

## Modules

| Name                                         | Source                        | Version |
| -------------------------------------------- | ----------------------------- | ------- |
| <a name="module_db"></a> [db](#module_db)    | terraform-aws-modules/rds/aws | 5.2.3   |
| <a name="module_vpc"></a> [vpc](#module_vpc) | terraform-aws-modules/vpc/aws | 3.19.0  |

## Resources

| Name                                                                                                                                                                        | Type        |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_apprunner_service.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_service)                                               | resource    |
| [aws_apprunner_vpc_connector.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_vpc_connector)                                   | resource    |
| [aws_apprunner_vpc_ingress_connection.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_vpc_ingress_connection)                 | resource    |
| [aws_db_subnet_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group)                                                      | resource    |
| [aws_iam_instance_profile.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile)                                        | resource    |
| [aws_iam_policy.pvault_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                                         | resource    |
| [aws_iam_policy.pvault_parameter_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                             | resource    |
| [aws_iam_policy.pvault_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)                                                     | resource    |
| [aws_iam_role.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                                | resource    |
| [aws_iam_role.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                                 | resource    |
| [aws_iam_role_policy_attachment.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)                            | resource    |
| [aws_iam_role_policy_attachment.pvault_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)                         | resource    |
| [aws_iam_role_policy_attachment.pvault_parameter_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)             | resource    |
| [aws_iam_role_policy_attachment.pvault_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)                     | resource    |
| [aws_instance.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)                                                                | resource    |
| [aws_kms_alias.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias)                                                               | resource    |
| [aws_kms_key.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key)                                                                   | resource    |
| [aws_secretsmanager_secret.db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)                                  | resource    |
| [aws_secretsmanager_secret.pvault_service_admin_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)                 | resource    |
| [aws_secretsmanager_secret.pvault_service_license](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret)                       | resource    |
| [aws_secretsmanager_secret_version.db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version)                  | resource    |
| [aws_secretsmanager_secret_version.pvault_service_admin_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource    |
| [aws_secretsmanager_secret_version.pvault_service_license](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version)       | resource    |
| [aws_security_group.apprunner_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                         | resource    |
| [aws_security_group.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                    | resource    |
| [aws_security_group.open](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                       | resource    |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                        | resource    |
| [aws_ssm_parameter.db_hostname](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)                                                  | resource    |
| [aws_vpc_endpoint.apprunner_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint)                                             | resource    |
| [random_password.pvault_service_admin_api_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)                                     | resource    |
| [aws_ami.amazon_linux_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)                                                                | data source |
| [aws_arn.db_hostname](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn)                                                                   | data source |
| [aws_arn.db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn)                                                                   | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones)                                       | data source |

## Inputs

| Name                                                                                                | Description                                                                              | Type           | Default                                         | Required |
| --------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | -------------- | ----------------------------------------------- | :------: |
| <a name="input_allowed_cidr_blocks"></a> [allowed_cidr_blocks](#input_allowed_cidr_blocks)          | The subnets CIDRs which allowed to access the RDS                                        | `list(string)` | `[]`                                            |    no    |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region)                                     | AWS region to deploy vault                                                               | `string`       | `"us-east-2"`                                   |    no    |
| <a name="input_create_bastion"></a> [create_bastion](#input_create_bastion)                         | n/a                                                                                      | `bool`         | `true`                                          |    no    |
| <a name="input_create_client_bastion"></a> [create_client_bastion](#input_create_client_bastion)    | n/a                                                                                      | `bool`         | `true`                                          |    no    |
| <a name="input_create_vpc"></a> [create_vpc](#input_create_vpc)                                     | n/a                                                                                      | `bool`         | `true`                                          |    no    |
| <a name="input_database_subnet_ids"></a> [database_subnet_ids](#input_database_subnet_ids)          | The Database subnets where the RDS will deploy                                           | `list(string)` | `[]`                                            |    no    |
| <a name="input_private_subnet_ids"></a> [private_subnet_ids](#input_private_subnet_ids)             | The Private subnets where the Pvault will deploy                                         | `list(string)` | `[]`                                            |    no    |
| <a name="input_pvault_image"></a> [pvault_image](#input_pvault_image)                               | Pvault image:tag public image                                                            | `string`       | `"public.ecr.aws/w6p8i1g8/pvault-server:1.1.3"` |    no    |
| <a name="input_pvault_port"></a> [pvault_port](#input_pvault_port)                                  | Pvault application port number                                                           | `string`       | `"8123"`                                        |    no    |
| <a name="input_pvault_service_license"></a> [pvault_service_license](#input_pvault_service_license) | Pvault license code <https://piiano.com/docs/guides/install/pre-built-docker-containers> | `string`       | n/a                                             |   yes    |
| <a name="input_rds_allocated_storage"></a> [rds_allocated_storage](#input_rds_allocated_storage)    | Pvault RDS initial allocated storage in GB                                               | `number`       | `"20"`                                          |    no    |
| <a name="input_rds_db_name"></a> [rds_db_name](#input_rds_db_name)                                  | Pvault RDS database name                                                                 | `string`       | `"pvault"`                                      |    no    |
| <a name="input_rds_instance_class"></a> [rds_instance_class](#input_rds_instance_class)             | Pvault RDS instance class                                                                | `string`       | `"db.t4g.medium"`                               |    no    |
| <a name="input_rds_port"></a> [rds_port](#input_rds_port)                                           | Pvault RDS port                                                                          | `string`       | `"5432"`                                        |    no    |
| <a name="input_rds_username"></a> [rds_username](#input_rds_username)                               | Pvault RDS username                                                                      | `string`       | `"pvault"`                                      |    no    |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)                                                 | The existing VPC_ID                                                                      | `string`       | `""`                                            |    no    |

## Outputs

| Name                                                           | Description |
| -------------------------------------------------------------- | ----------- |
| <a name="output_authtoken"></a> [authtoken](#output_authtoken) | n/a         |
| <a name="output_vault_url"></a> [vault_url](#output_vault_url) | n/a         |

<!-- END_TF_DOCS -->
