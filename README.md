<p>
  <a href="https://piiano.com/pii-data-privacy-vault/">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://docs.piiano.com/img/logo-developers-dark.svg">
      <source media="(prefers-color-scheme: light)" srcset="https://docs.piiano.com/img/logo-developers.svg">
      <img alt="Piiano Vault" src="https://docs.piiano.com/img/logo-developers.svg" height="40" />
    </picture>
  </a>
</p>

# Piiano Vault

**The secure home for sensitive personal data**

Safely store sensitive personal data in your own cloud environment with automated compliance controls. [More details](#about-piiano-vault)

## Vault Deployments

This repository contains deployments for Vault in cloud environments.
Each of these folders can be used independently to deploy Vault in its respective cloud and technology:

1. [AWS AppRunner](./aws-apprunner)  
   Vault deployed in an AppRunner container. Provided is also a [demo application](./aws-apprunner-nodejs-demo-app) using another AppRunner container to demonstrate connecting to the Vault and running basic commands.

1. [AWS ECS](./aws-ecs)  
   Vault deployed in an ECS container.

1. [GCP Cloud Run](./gcp-cloud-run)  
   Vault deployed in GCP Cloud Run.

# About Piiano Vault

Piiano Vault is the secure home for sensitive personal data. It allows you to safely store sensitive personal data in your own cloud environment with automated compliance controls.

Vault is deployed within your own architecture, next to other DBs used by the applications, and should be used to store the most critical sensitive personal data, such as credit cards and bank account numbers, names, emails, national IDs (e.g. SSN), phone numbers, etc.

The main benefits are:

- Field level encryption, including key rotation.
- Searchability is allowed over the encrypted data.
- Full audit log for all data accesses.
- Granular access controls.
- Easy masking and tokenization of data.
- Out of the box privacy compliance functionality.

More details can be found [on our website](https://piiano.com/pii-data-privacy-vault/) and on the [developers portal](https://piiano.com/docs/).
