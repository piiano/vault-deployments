provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Deployment_id = var.deployment_id
      Terraform     = true
      Service       = "Piiano Vault Server"
    }
  }
}
