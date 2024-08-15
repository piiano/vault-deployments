# Contributing to Piiano Vault deployments

The platform specific deployments leverage Terraform as a tool to create the necessary resources and configuration.

It is important that high standards are maintained, unreliable logic and/or breaking changes could cause downtime and frustration for users.

## Terraform code style and structure

Follow the general guidelines documented [here](https://cloud.google.com/docs/terraform/best-practices/general-style-structure).

A list of variables and requirements for the module should be in the `README.md` file.
This can be generated with `terraform-docs`, example:

```sh
terraform-docs markdown --output-file README.md .
```

## Tooling version

Tools used in this repo and their versions are defined in the `.tool-versions` file.

[Mise](https://github.com/jdx/mise) (recommended) or [asdf](https://github.com/asdf-vm/asdf) can be used to automatically install and activate the necessary tooling.
