# Terraform for Piiano Vault AWS App Runner

This module deploys Piiano Vault on a given AWS region. It will outputs the private Vault URL post deployment.

This application version is 1.6.2 and is compatible with Vault version 1.6.2 .

## Solution Architecture

Vault is deployed as a single App Runner regional service. The service is deployed in the App Runner VPC and is configured for private access only from the `pvault-vpc`.
Internally, Vault communicates with a Postgres RDS that resides in the database subnet.

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
  source               = "./aws-apprunner"
  pvault_service_license = "eyJhbGc..."
}
```

### Installation

```sh
terraform init
terraform apply
```

### Post installation

When a successful installation completes, it shows the following output:

```sh
authtoken = "Secret Manager: /pvault/pvault_service_admin_api_key --> retrieve value"
vault_url = "https://<random dns>.<region>.awsapprunner.com"
```

To check that the Vault is working as expected run the following from inside the application VPC. Optionally, the deployment script can deploy a bastion machine for this purpose:

```sh
alias pvault="docker run --rm -i -v $(pwd):/pwd -w /pwd piiano/pvault-cli:1.6.2"
pvault --addr <VAULT URL from above> --authtoken '<token from the secret manager>' selftest basic
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.67.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.51 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.52.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.5.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_db"></a> [db](#module\_db) | terraform-aws-modules/rds/aws | 5.2.3 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.19.0 |

## Resources

| Name | Type |
|------|------|
| [aws_apprunner_service.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_service) | resource |
| [aws_apprunner_vpc_connector.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_vpc_connector) | resource |
| [aws_apprunner_vpc_ingress_connection.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_vpc_ingress_connection) | resource |
| [aws_iam_instance_profile.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_instance.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_kms_alias.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.pvault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_secretsmanager_secret.db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.pvault_service_admin_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.pvault_service_license](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.pvault_service_admin_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.pvault_service_license](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.apprunner_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.open](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.apprunner_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [random_password.pvault_service_admin_api_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_ami.amazon_linux_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_arn.db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidr_blocks"></a> [allowed\_cidr\_blocks](#input\_allowed\_cidr\_blocks) | The subnets CIDRs which allowed to access the Pvault service | `list(string)` | `[]` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy vault | `string` | `"us-east-2"` | no |
| <a name="input_create_bastion"></a> [create\_bastion](#input\_create\_bastion) | Controls if a new EC2 bastion should be created in VPC | `bool` | `false` | no |
| <a name="input_create_client_bastion"></a> [create\_client\_bastion](#input\_create\_client\_bastion) | n/a | `bool` | `true` | no |
| <a name="input_create_secret_license"></a> [create\_secret\_license](#input\_create\_secret\_license) | Controls if the secret license should be created. If set to 'false', var.secret\_arn\_license must be set | `bool` | `true` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Controls if VPC should be created (it affects almost all resources) | `bool` | `true` | no |
| <a name="input_database_subnet_ids"></a> [database\_subnet\_ids](#input\_database\_subnet\_ids) | The IDs if the Database subnets where the RDS will deploy | `list(string)` | `[]` | no |
| <a name="input_deployment_id"></a> [deployment\_id](#input\_deployment\_id) | The unique deployment id of this deployment | `string` | `"pvault"` | no |
| <a name="input_instance_cpu"></a> [instance\_cpu](#input\_instance\_cpu) | The number of CPU units for the Pvault instance. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_service#instance-configuration for more details. | `number` | `1024` | no |
| <a name="input_instance_memory"></a> [instance\_memory](#input\_instance\_memory) | The amount of memory in MiB for the Pvault instance. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_service#instance-configuration for more details. | `number` | `2048` | no |
| <a name="input_is_publically_accessible"></a> [is\_publically\_accessible](#input\_is\_publically\_accessible) | Controls if the Pvault service should be publically accessible | `bool` | `false` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | The IDs of the private subnets where the Pvault service will deploy | `list(string)` | `[]` | no |
| <a name="input_pvault_admin_may_read_data"></a> [pvault\_admin\_may\_read\_data](#input\_pvault\_admin\_may\_read\_data) | Whether Admin is allowed to read data. See https://piiano.com/docs/guides/configure/environment-variables#service-and-features for more details. | `bool` | `false` | no |
| <a name="input_pvault_devmode"></a> [pvault\_devmode](#input\_pvault\_devmode) | Enable devmode for Pvault. See https://piiano.com/docs/guides/configure/environment-variables#production-and-development-mode for more details. | `bool` | `false` | no |
| <a name="input_pvault_env_vars"></a> [pvault\_env\_vars](#input\_pvault\_env\_vars) | A map of environment variables to set for the Pvault service. See https://piiano.com/docs/guides/configure/environment-variables for more details. | `map(string)` | `{}` | no |
| <a name="input_pvault_log_customer_env"></a> [pvault\_log\_customer\_env](#input\_pvault\_log\_customer\_env) | Identifies the environment in all the observability platforms. Recommended values are PRODUCTION, STAGING, and DEV | `string` | n/a | yes |
| <a name="input_pvault_log_customer_identifier"></a> [pvault\_log\_customer\_identifier](#input\_pvault\_log\_customer\_identifier) | Identifies the customer in all the observability platforms | `string` | n/a | yes |
| <a name="input_pvault_port"></a> [pvault\_port](#input\_pvault\_port) | Pvault application port number | `string` | `"8123"` | no |
| <a name="input_pvault_repository"></a> [pvault\_repository](#input\_pvault\_repository) | Pvault repository public image | `string` | `"public.ecr.aws/s4s5s6q8/pvault-server"` | no |
| <a name="input_pvault_service_license"></a> [pvault\_service\_license](#input\_pvault\_service\_license) | Pvault license code https://piiano.com/docs/guides/install/pre-built-docker-containers. Cannot be set if var.create\_secret\_license is set to 'true' | `string` | `""` | no |
| <a name="input_pvault_tag"></a> [pvault\_tag](#input\_pvault\_tag) | n/a | `string` | `"1.6.1"` | no |
| <a name="input_rds_allocated_storage"></a> [rds\_allocated\_storage](#input\_rds\_allocated\_storage) | Pvault RDS initial allocated storage in GB | `number` | `"20"` | no |
| <a name="input_rds_backup_retention_period"></a> [rds\_backup\_retention\_period](#input\_rds\_backup\_retention\_period) | The days to retain backups for RDS. Possible values are 0-35 | `string` | `7` | no |
| <a name="input_rds_db_name"></a> [rds\_db\_name](#input\_rds\_db\_name) | Pvault RDS database name | `string` | `"pvault"` | no |
| <a name="input_rds_instance_class"></a> [rds\_instance\_class](#input\_rds\_instance\_class) | Pvault RDS instance class | `string` | `"db.t4g.medium"` | no |
| <a name="input_rds_port"></a> [rds\_port](#input\_rds\_port) | Pvault RDS port | `string` | `"5432"` | no |
| <a name="input_rds_username"></a> [rds\_username](#input\_rds\_username) | Pvault RDS username | `string` | `"pvault"` | no |
| <a name="input_secret_arn_license"></a> [secret\_arn\_license](#input\_secret\_arn\_license) | The ARN of the Secrets Manager secret of Pvault license. If var.create\_secret\_license is set to 'true', this variable is ignored | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The existing VPC\_ID in case that `create_vpc` is false | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apprunner_service_arn"></a> [apprunner\_service\_arn](#output\_apprunner\_service\_arn) | n/a |
| <a name="output_bastion_instance_id"></a> [bastion\_instance\_id](#output\_bastion\_instance\_id) | n/a |
| <a name="output_pvault_api_key"></a> [pvault\_api\_key](#output\_pvault\_api\_key) | n/a |
| <a name="output_pvault_url"></a> [pvault\_url](#output\_pvault\_url) | n/a |
<!-- END_TF_DOCS -->
